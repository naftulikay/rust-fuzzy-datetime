use curl::easy::Easy;
use std::process::exit;

fn main() {
    // make sure we can initialize openssl
    test_openssl();
    // make sure we can use curl
    test_curl();
}

fn test_curl() {
    curl::init();

    let mut output = Vec::new();
    let mut handle = Easy::new();
    handle.url("https://www.google.com").unwrap();

    {
        let mut transfer = handle.transfer();
        transfer
            .write_function(|new_data| {
                output.extend_from_slice(new_data);
                Ok(new_data.len())
            })
            .unwrap();
        transfer.perform().unwrap();
    }

    if handle.response_code().unwrap() != 200 {
        eprintln!(
            "GET https://www.google.com/ returned {}",
            handle.response_code().unwrap()
        );
        exit(1)
    }
}

fn test_openssl() {
    openssl::init();
}
