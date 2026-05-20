// Characterization pattern: compiled binary via subprocess
// Covers: C++ → Rust migrations
//
// Run the C++ binary with controlled input and compare its output
// to a saved golden file. First run saves the reference; later runs assert no change.

use std::fs;
use std::process::Command;

const GOLDEN: &str = "tests/golden/compute_output.txt";

#[test]
fn characterizes_compute_at_nominal_input() {
    let output = Command::new("./build/legacy_compute")
        .arg("1.0")
        .output()
        .expect("failed to run legacy binary");

    let actual = String::from_utf8_lossy(&output.stdout).trim().to_string();

    if !std::path::Path::new(GOLDEN).exists() {  // first run: save the reference
        fs::create_dir_all("tests/golden").unwrap();
        fs::write(GOLDEN, &actual).unwrap();
        return;
    }

    let expected = fs::read_to_string(GOLDEN).unwrap().trim().to_string();
    assert_eq!(actual, expected);
}
