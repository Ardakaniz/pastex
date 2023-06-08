use std::net::SocketAddr;

use axum::Router;
use tower_http::services::ServeDir;

#[tokio::main]
async fn main() {
    // build our application with a route
    let app = Router::new().nest_service("/", ServeDir::new("./client/dist"));

    // run our app with hyper
    // `axum::Server` is a re-export of `hyper::Server`
    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}
