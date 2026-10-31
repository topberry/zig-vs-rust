use std::{io};

mod minheap;

// Incredible software engineering achieving O(n log n) sorting
// in rust: Blazingly fast times 2 !!!
#[allow(dead_code)]
fn heapsort(v: Vec<i32>) -> Vec<i32> {

    let size = v.len();
    let mut heap = minheap::MinHeap::from_vector(v);
    let mut ret = vec![];

    for _ in 0..size {
        ret.push( heap.extract_min().unwrap() );
    };

    ret

}

fn main() -> io::Result<()> {

    let mut heap = minheap::MinHeap::new();

    for line in io::stdin().lines() {

        match line.unwrap() {

            s if s.starts_with("I ") => heap.insert( s.strip_prefix("I ").unwrap().to_string().parse().unwrap() ),
            s if s.starts_with("E") => println!( "{}", heap.extract_min().unwrap() ),
            _ => {}

        };

    };

    Ok(())

}

#[test]
fn heapsort_test() {

    let input = vec![142124,4214124,1242,44,564,73,44513,41224653,735642,45141464,46,635,3,43,56,75,734,64,5];
    let sorted = heapsort(input);

    assert!( sorted.is_sorted() );

}


#[test]
fn test_heap() {

    let mut heap = minheap::MinHeap::from_vector(vec![2,3,1,3]);

    assert!( heap.size() == 4 );

    assert!( *&heap.extract_min().unwrap() == 1 );
    assert!( *&heap.extract_min().unwrap() == 2 );
    assert!( *&heap.extract_min().unwrap() == 3 );
    assert!( *&heap.extract_min().unwrap() == 3 );
    assert!( *&heap.extract_min() == None );

    assert!( heap.size() == 0 );

    *&heap.insert(432);
    *&heap.insert(14);
    *&heap.insert(4);
    *&heap.insert(0);

    assert!( heap.size() == 4 );

    assert!( *&heap.extract_min().unwrap() == 0 );
    assert!( *&heap.extract_min().unwrap() == 4 );
    assert!( *&heap.extract_min().unwrap() == 14 );
    assert!( *&heap.extract_min().unwrap() == 432 );

    assert!( heap.size() == 0 );

}
