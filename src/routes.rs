use std::collections::HashMap;
use std::convert::Infallible;

use warp::Filter;

use futures_util::{FutureExt, StreamExt};

use crate::db::Db;
use crate::handlers;

/** HELPERS **/

// Passing database
fn with_db<'a>(db: Db<'a>) -> impl Filter<Extract = (Db,), Error = Infallible> + Clone + 'a {
	warp::any().map(move || db.clone())
}

/** TOP LEVEL ROUTE **/
pub fn pastex_routes<'a>(
	db: Db<'a>,
) -> impl Filter<Extract = impl warp::Reply, Error = Infallible> + Clone + 'a {
	index(db.clone())
		.or(favicon())
		.or(static_files())
		.or(query_paste(db.clone()))
		.or(open_paste(db.clone()))
		.or(view_pdf(db))
		.or(websocket())
		.or(warp::any().map(handlers::not_found))
}

/** ROUTES **/

// GET /
// Serves the index w/ optional queries (prefilled id and/or info about invalid access)
fn index<'a>(
	db: Db<'a>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone + 'a {
	warp::get()
		.and(warp::path!())
		.and(warp::query::<HashMap<String, String>>())
		.and(with_db(db))
		.and_then(handlers::index)
		.with(warp::compression::gzip())
}

// GET /static/...
// Serves static files
fn static_files() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
	warp::get()
		.and(warp::path!("static" / ..))
		.and(warp::fs::dir("dist/static"))
		.with(warp::compression::gzip())
}

// POST /?id=...&pwd=...
// Sent from the index, to open a paste (may be rejected by handlers::access_paste)
fn query_paste<'a>(
	db: Db<'a>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone + 'a {
	warp::post()
		.and(warp::path!())
		.and(warp::body::content_length_limit(1024 * 32))
		.and(warp::body::form())
		.and(with_db(db.clone()))
		.and_then(handlers::query_paste)
		.with(warp::compression::gzip())
}

// GET /e/{id}
// Directly accessed, to open a paste (may be rejected by handlers::access_paste)
fn open_paste<'a>(
	db: Db<'a>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone + 'a {
	warp::get()
		.and(warp::path!("e" / String))
		.map(|id| (id, None))
		.and(with_db(db))
		.and_then(handlers::access_paste)
		.with(warp::compression::gzip())
}

// GET /e/{id}/view
// Direct access to the paste's PDF render
fn view_pdf<'a>(
	db: Db<'a>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone + 'a {
	warp::get()
		.and(warp::path!("e" / String / "view"))
		.and(with_db(db))
		.and_then(handlers::pdf_view)
		.with(warp::compression::gzip())
}

// GET favicon.ico
// Create additional routes for favicon in order for the browser to find it
fn favicon() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
	warp::get()
		.and(warp::path!("favicon.ico"))
		.and(warp::fs::file("dist/static/favicon.ico"))
		.with(warp::compression::gzip())
}

// ws://host/
// Handles websockets
fn websocket() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
	warp::ws().and(warp::path!()).map(|ws: warp::ws::Ws| {
		// And then our closure will be called when it completes...
		ws.on_upgrade(|websocket| {
			// Just echo all messages back...
			let (tx, rx) = websocket.split();
			rx.forward(tx).map(|result| {
				if let Err(e) = result {
					eprintln!("websocket error: {:?}", e);
				}
			})
		})
	})
}
