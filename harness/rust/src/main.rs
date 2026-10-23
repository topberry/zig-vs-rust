use std::io::{self, BufRead, Write};
use zig_vs_rust::MinBinHeap;

fn main() {
    if let Err(e) = run() {
        eprintln!("{e}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let stdin = io::stdin();
    let mut stdout = io::stdout().lock();
    let mut heap = MinBinHeap::<i64>::new();

    for line in stdin.lock().lines() {
        let line = line.map_err(|e| e.to_string())?;
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        let mut parts = trimmed.split_whitespace();
        let op = parts.next().ok_or_else(|| "missing op".to_string())?;
        match op {
            "I" => {
                let arg = parts.next().ok_or_else(|| "missing insert arg".to_string())?;
                let v: i64 = arg
                    .parse()
                    .map_err(|_| format!("bad insert value: {arg}"))?;
                heap.insert(v);
            }
            "E" => match heap.extract_min() {
                Some(v) => writeln!(stdout, "{v}").map_err(|e| e.to_string())?,
                None => writeln!(stdout, "-").map_err(|e| e.to_string())?,
            },
            other => return Err(format!("unknown op: {other}")),
        }
    }
    stdout.flush().map_err(|e| e.to_string())?;
    Ok(())
}
