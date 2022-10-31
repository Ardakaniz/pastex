use std::fs;
use std::net::SocketAddrV4;
use std::sync::{Arc, Mutex};

use tinyrand::{Rand, Seeded, StdRand};

use handlebars::Handlebars;
use serde_json::Value;
use warp::Filter;

pub struct ServerData<'a> {
    rand: StdRand,
    handlebars: Handlebars<'a>,
    params: Value,

    socket: SocketAddrV4,
}

impl<'a> ServerData<'a> {
    pub fn from_file(filepath: &str) -> Self {
        let contents = fs::read_to_string(filepath)
            .unwrap_or_else(|_| panic!("Failed to open param file: '{}'", filepath));

        Self::from_json(
            &serde_json::from_str(&contents)
                .unwrap_or_else(|_| panic!("Failed to read param file '{}'", filepath)),
        )
    }

    pub fn from_json(params: &Value) -> Self {
        let mut handlebars = Handlebars::new();
        handlebars.set_dev_mode(true); // TO REMOVE IN PROD
        handlebars
            .register_template_file("editor", "dist/editor.html")
            .unwrap();

        let socket = params["socket"]
            .as_str()
            .unwrap_or("127.0.0.1:8080")
            .parse::<SocketAddrV4>()
            .expect("Failed to parse socket");

        ServerData {
            rand: StdRand::seed(params["seed"].as_u64().unwrap_or_default()),
            handlebars,
            params: params.clone(),

            socket,
        }
    }

    pub fn generate_uid(&mut self) -> String {
        let alphanum =
            String::from("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
        let mut uid = String::new();
        for _ in 0..5 {
            let alphanum_id = self.rand.next_lim_usize(alphanum.len());
            uid.push(alphanum.chars().nth(alphanum_id).unwrap());
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
        warp::any().map(move || data.clone())
    };

    let index = warp::get()
        .and(warp::path::end())
        .and(warp::fs::file("dist/index.html"));

    let new_paste = warp::post()
        .and(warp::body::content_length_limit(1024 * 32))
        .and(warp::body::form())
        .map(handlers::open_paste);

    let statics = warp::get()
        .and(warp::path("static"))
        .and(warp::fs::dir("dist/static"));

    let favico = warp::get()
        .and(warp::path("favicon.ico"))
        .and(warp::fs::file("dist/static/favicon.ico"));

    let editor = warp::get()
        .and(warp::path!("p" / String))
        .and(data_filter())
        .map(handlers::editor);

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
        .or(warp::any().map(handlers::not_found));

    let socket = data.lock().unwrap().socket;

    println!("Running server on {}...", socket);
    warp::serve(routes)
        .run((socket.ip().octets(), socket.port()))
        .await;
}

mod handlers {
    use crate::DataWrapper;
    use std::collections::HashMap;
    use warp::http::{StatusCode, Uri};

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

        let hdb = &data.lock().unwrap().handlebars;
        let tpl_params = HashMap::from([("id", id)]);

        warp::reply::html(hdb.render("editor", &tpl_params).unwrap())
    }

    pub fn not_found() -> impl warp::Reply {
        warp::reply::with_status("Page non trouvée", StatusCode::NOT_FOUND)
    }
}
