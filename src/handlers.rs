use std::collections::HashMap;
use std::convert::Infallible;

use futures_util::TryFutureExt;
use warp::http::{StatusCode, Uri};

use crate::db::Db;

pub async fn index(
	query: HashMap<String, String>,
	db: Db<'_>,
) -> Result<impl warp::Reply, Infallible> {
	let hdb = &db.lock().unwrap().handlebars;
	let tpl_params = HashMap::from([("id", query.get("id").cloned().unwrap_or(String::new()))]);

	Ok(warp::reply::html(hdb.render("index", &tpl_params).unwrap()))
}

pub async fn query_paste(
	queries: HashMap<String, String>,
	db: Db<'_>,
) -> Result<impl warp::Reply, warp::Rejection> {
	println!(
		"Opening paste with id {:?} and pwd {:?}",
		queries.get("id"),
		queries.get("pwd")
	); // debug purpose

	let id = queries
		.get("id")
		.cloned()
		.unwrap_or_else(|| db.lock().unwrap().generate_uid());

	let pwd = queries.get("pwd").cloned();

	access_paste((id, pwd), db).await
}

pub async fn access_paste(
	creds: (String, Option<String>),
	db: Db<'_>,
) -> Result<impl warp::Reply, warp::Rejection> {
	let (id, pwd) = match creds {
		(id, pwd) => (
			if id.is_empty() {
				// Generate uid if id is empty ; TODO: regenerate if already existing
				db.lock().unwrap().generate_uid()
			} else {
				id
			},
			pwd,
		),
	};

	if id == "pwdtest" && pwd != Some("Geronimo".into()) {
		Err(warp::reject::not_found()) // todo: create proper rejection
	} else {
		Ok(editor(id, db).await.unwrap())
	}
}

pub async fn editor(id: String, db: Db<'_>) -> Result<impl warp::Reply, Infallible> {
	let db = &db.lock().unwrap();
	// let ws_addr = "ws://".to_owned() + &db.get_socket().to_string();
	let hdb = &db.handlebars;
	let tpl_params = HashMap::from([
		("id", id),
		(
			"original_content",
			r"\\begin{equation}\n\te^{i\\pi} + 1 = 0\n\\end{equation}".into(),
		),
		//("ws_addr", ws_addr),
	]);

	Ok(warp::reply::html(
		hdb.render("editor", &tpl_params).unwrap(),
	))
}

pub async fn pdf_view(_id: String, _db: Db<'_>) -> Result<impl warp::Reply, Infallible> {
	/*
	Response::builder()
			.status(StatusCode::PROCESSING)
			.body(())
			.unwrap()
	*/
	Ok(warp::reply::with_status(
		"heyo let me compile",
		StatusCode::OK,
	))
}

pub fn not_found() -> impl warp::Reply {
	warp::reply::with_status("Page non trouvée", StatusCode::NOT_FOUND)
}
