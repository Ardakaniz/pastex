use std::fs;
use std::sync::{Arc,Mutex};

use tinyrand::{Rand, StdRand, Seeded};

use serde_json::{Value, json};
use handlebars::Handlebars;
use warp::Filter;

pub struct ServerData<'a> {
	rand: StdRand,
	handlebars: Handlebars<'a>,
	params: Value,
	
	address: [u8; 4],
	port: u16,
}

impl<'a> ServerData<'a> {
	pub fn from_file(filepath: &str) -> Self {
		let contents = fs::read_to_string(filepath)
				.expect(&format!("Failed to open param file: '{}'", filepath));

		Self::from_json(&serde_json::from_str(&contents).expect(&format!("Failed to read param file '{}'", filepath)))
	}

	pub fn from_json(params: &Value) -> Self {
		let mut handlebars = Handlebars::new();
		handlebars.set_dev_mode(true); // TO REMOVE IN PROD
		handlebars.register_template_file("editor", "dist/editor.html").unwrap();

		let address =
			params["address"]
				.as_array()
				.or(Some(json!([127, 0, 0, 1]).as_array().unwrap()))
				.filter(|x| x.len() == 4)
					.expect("Invalid IP address length")
				.iter()
				.map(|x| x.as_u64().and_then(|x| x.try_into().ok()).expect("Invalid IP address"))
				.collect::<Vec<u8>>()
				.try_into()
				.unwrap()
				;

		let port = 
			params["port"]
				.as_u64()
				.and_then(|x| x.try_into().ok())
				.unwrap_or(8080)
				;
		
		ServerData {
			rand: StdRand::seed(params["seed"].as_u64().unwrap_or_default()),
			handlebars,
			params: params.clone(),

			address,
			port,
		}
	}

	pub fn generate_uid(&mut self) -> String {
		let alphanum = String::from("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
		let mut uid = String::new();
		for _ in 0..5 {
			let alphanum_id = self.rand.next_lim_usize(alphanum.len());
			uid.push(
				alphanum
					.chars()
					.nth(alphanum_id)
					.unwrap()
			);
		}
	
		uid
	}
}

type DataWrapper<'a> = Arc<Mutex<ServerData<'a>>>;

#[tokio::main]
async fn main() {
	// CODE MIRROR !!
	
	let data = Arc::new(Mutex::new(ServerData::from_file("data/data.json")));
	let data_filter = || {
		let data = data.clone();
		warp::any().map({
			move || data.clone()
		})
	};

	let index = warp::get()
		.and(warp::path::end())
		.and(warp::fs::file("dist/index.html"))
		;

	let new_paste = warp::post()
		.and(warp::body::content_length_limit(1024 * 32))
		.and(warp::body::form())
		.map(handlers::open_paste)
		;

	let statics = warp::get()
		.and(warp::path("static"))
		.and(warp::fs::dir("dist/static"))
		;

	let favico = warp::get()
		.and(warp::path("favicon.ico"))
		.and(warp::fs::file("dist/static/favicon.ico"))
		;

	let editor = warp::get()
		.and(warp::path!("p" / String))
		.and(data_filter())
		.map(handlers::editor)
		;

	let new_paste_from_url = warp::get()
		.and(warp::path!("p"))
		.and(data_filter())
		.map(handlers::new_paste);

	let routes = index
		.or(statics)
		.or(new_paste)
		.or(favico)
		.or(new_paste_from_url)
		.or(editor)
		.or(warp::any().map(handlers::not_found))
		;

	let address = data.lock().unwrap().address;
	let port    = data.lock().unwrap().port;

	println!("Running server on {address:?}:{port}...");
	warp::serve(routes).run((address, port)).await;
}

mod handlers {
	use crate::DataWrapper;
	use warp::http::{StatusCode, Uri};
	use std::collections::HashMap;

	pub fn open_paste(content: HashMap<String, String>) -> impl warp::Reply {
		let url = "/p/".to_owned() + &content["id"];
		warp::redirect::see_other(Uri::builder().path_and_query(url).build().unwrap())
	}

	pub fn new_paste(data: DataWrapper<'_>) -> impl warp::Reply {
		let uid = data.lock().unwrap().generate_uid();
		let url = "/p/".to_owned() + uid.as_str();

		println!("new_paste_from_url");
		
		warp::redirect::see_other(Uri::builder().path_and_query(url).build().unwrap())
	}

	pub fn editor(id: String, data: DataWrapper<'_>) -> impl warp::Reply {
		println!("editor {}", id);

		let hdb = &data.lock()
							.unwrap()
							.handlebars
							;
		let tpl_params = HashMap::from([
			("id", id)
		]);

		warp::reply::html(hdb.render("editor", &tpl_params).unwrap())
	}

	pub fn not_found() -> impl warp::Reply {
		warp::reply::with_status("Page non trouvée", StatusCode::NOT_FOUND)
	}
}