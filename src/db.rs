use std::fs;
use std::net::SocketAddrV4;
use std::sync::{Arc, Mutex};

use handlebars::Handlebars;
use serde_json::Value;
use tinyrand::{Rand, Seeded, StdRand};

pub struct Data<'a> {
	rand: StdRand,
	pub handlebars: Handlebars<'a>,
	pub params: Value,

	socket: SocketAddrV4,
}

pub type Db<'a> = Arc<Mutex<Data<'a>>>;

impl<'a> Data<'a> {
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
			.register_template_file("index", "dist/index.html")
			.unwrap();

		handlebars
			.register_template_file("editor", "dist/editor.html")
			.unwrap();

		let socket = params["socket"]
			.as_str()
			.unwrap_or("127.0.0.1:8080")
			.parse::<SocketAddrV4>()
			.expect("Failed to parse socket");

		Data {
			rand: StdRand::seed(params["seed"].as_u64().unwrap_or_default()),
			handlebars,
			params: params.clone(),

			socket,
		}
	}

	pub fn get_socket(&self) -> &SocketAddrV4 {
		&self.socket
	}

	pub fn generate_uid(&mut self) -> String {
		let alphanum = String::from("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
		let uid_length: usize = 5;

		let mut uid = String::with_capacity(uid_length);
		for _ in 0..uid_length {
			let alphanum_id = self.rand.next_lim_usize(alphanum.len());
			uid.push(alphanum.chars().nth(alphanum_id).unwrap());
		}

		uid
	}
}

pub fn init_from_file(filepath: &str) -> (Db, SocketAddrV4) {
	let data = Data::from_file(filepath);
	let socket = data.socket;

	(Arc::new(Mutex::new(data)), socket)
}

pub fn init_from_json(params: &Value) -> (Db, SocketAddrV4) {
	let data = Data::from_json(params);
	let socket = data.socket;

	(Arc::new(Mutex::new(data)), socket)
}
