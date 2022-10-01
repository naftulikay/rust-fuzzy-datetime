use chrono::{TimeZone, Utc};
use chrono_tz::US::{Eastern, Pacific};
use curl::easy::Easy;
use std::env;
use std::fs;
use std::path::Path;
use std::process::exit;

/// This binary tests that static linking has successfully built all dependencies into the final
/// binary, and is meant to be executed within a `scratch` Docker image to determine that the image
/// contains everything necessary to execute at runtime.
///
/// This binary is run within the Docker build process to determine this at image creation time,
/// rather than waiting for the main binary to fail at container start time. Certain libraries like
/// OpenSSL and cURL should be tested here to make sure they work. An HTTP GET to any site over TLS
/// should prove that the binary has everything it needs.
///
/// Additionally, an HTTP GET to any HTTPS site will also prove that the TLS CA certificates are
/// present and that the image can validate the server accordingly.
///
/// If `--self-destruct` is passed, this application will remove `argv[0]`, which is the path to
/// this binary. This is so the final image contains nothing but
fn main() {
    // make sure we can initialize openssl
    test_openssl();
    // make sure we can use curl
    test_curl();
    // make sure that we can timezone
    test_time();

    eprintln!("*** static tests passed ✅");

    self_destruct();
}

/// If `--self-destruct` is passed anywhere in the arguments, this function will use `argv[0]` to
/// find itself on the filesystem and remove that file to keep Docker image size small.
fn self_destruct() {
    let argv: Vec<String> = env::args().collect();

    if let Some(executable) = argv.first() {
        let path = Path::new(executable);

        for arg in argv.iter().skip(1) {
            if arg == "--self-destruct" {
                if let Err(e) = fs::remove_file(path) {
                    eprintln!("*** error: unable to remove self as requested - {:?}", e);
                } else {
                    eprintln!("*** removed self ({})", path.display());
                    return;
                }
            }
        }
    }
}

/// Tests that libcurl has been successfully statically linked and functioning by making a HTTP
/// GET to https://www.google.com and validating that it returns 200.
///
/// A simple request like this will validate that OpenSSL is working, that cURL is working, and that
/// both are able to verify the server certificate against the certificate authorities (CAs) that
/// are included in the Docker image.
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

fn test_time() {
    let arbitrary = Utc.ymd(2020, 1, 22).and_hms(12, 34, 56);
    let _pst = arbitrary.with_timezone(&Pacific);
    let _est = arbitrary.with_timezone(&Eastern);
}

/// Tests that libssl (OpenSSL) has been successfully statically linked and functioning.
fn test_openssl() {
    openssl::init();
}
