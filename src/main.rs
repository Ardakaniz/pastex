mod db;
mod handlers;
mod routes;

#[tokio::main]
async fn main() {
	let (db, socket) = db::init_from_file("data/data.json");
	let pastex_routes = routes::pastex_routes(db);

	warp::serve(pastex_routes).run(socket).await;
}
