use std::process::Command;

fn main() {
    println!("cargo:rerun-if-changed=client/src");

    Command::new("npm")
        .arg("run")
        .arg("build")
        .current_dir("./client")
        .spawn()
        .expect("npm command failed to start");
}
