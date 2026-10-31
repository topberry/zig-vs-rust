use std::io::{self, BufRead, Write};

mod minheap;

use minheap::MinHeap;

// Incredible software engineering achieving O(n log n) sorting
// in rust: Blazingly fast times 2 !!!
#[allow(dead_code)]
fn heapsort(v: Vec<i64>) -> Vec<i64> {
    let size = v.len();
    let mut heap = MinHeap::from_vector(v);
    let mut ret = vec![];

    for _ in 0..size {
        ret.push(heap.extract_min().unwrap());
    }

    ret
}

fn main() {
    
    let stdin = io::stdin();
    let mut stdin = stdin.lock();
    let mut stdout = io::BufWriter::new(io::stdout().lock());
    let mut heap = MinHeap::new();

    let mut buf = Vec::with_capacity(64);
    loop {
        buf.clear();
        if stdin.read_until(b'\n', &mut buf).unwrap() == 0 {
            break;
        }
        let trimmed = String::from_utf8_lossy(&buf);
        let trimmed = trimmed.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        let mut parts = trimmed.split_whitespace();
        match parts.next().unwrap() {
            "I" => heap.insert(parts.next().unwrap().parse().unwrap()),
            "E" => match heap.extract_min() {
                Some(v) => writeln!(stdout, "{v}").unwrap(),
                None => writeln!(stdout, "-").unwrap(),
            },
            _ => unreachable!(),
        }
    }
    stdout.flush().unwrap();
}

#[test]
fn heapsort_test() {
    let input = vec![142124, 4214124, 1242, 44, 564, 73, 44513, 41224653, 735642, 45141464, 46, 635, 3, 43, 56, 75, 734, 64, 5];
    let sorted = heapsort(input);

    assert!(sorted.is_sorted());
}

#[test]
fn test_heap() {
    let mut heap = MinHeap::from_vector(vec![2, 3, 1, 3]);

    assert!(heap.size() == 4);

    assert!(*&heap.extract_min().unwrap() == 1);
    assert!(*&heap.extract_min().unwrap() == 2);
    assert!(*&heap.extract_min().unwrap() == 3);
    assert!(*&heap.extract_min().unwrap() == 3);
    assert!(*&heap.extract_min() == None);

    assert!(heap.size() == 0);

    *&heap.insert(432);
    *&heap.insert(14);
    *&heap.insert(4);
    *&heap.insert(0);

    assert!(heap.size() == 4);

    assert!(*&heap.extract_min().unwrap() == 0);
    assert!(*&heap.extract_min().unwrap() == 4);
    assert!(*&heap.extract_min().unwrap() == 14);
    assert!(*&heap.extract_min().unwrap() == 432);

    assert!(heap.size() == 0);
}
