use graphul::{Graphul, FolderConfig};

#[tokio::main]
async fn main() {
    let mut app = Graphul::new();

    app.static_files("/static", "public", FolderConfig::default());
   
    app.run("127.0.0.1:8000").await;
}