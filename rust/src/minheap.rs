#[derive(Debug)]
pub struct MinHeap {

    storage: Vec<i32>,

}

#[allow(dead_code)]
impl MinHeap {

    pub fn new() -> MinHeap {
        MinHeap { storage: vec![0] }
    }

    pub fn from_vector(init: Vec<i32>) -> MinHeap {

        let mut v = vec![0];
        init.iter().for_each(|i| v.push(*i));

        let vlen = v.len();

        let mut ret = MinHeap { storage: v };

        for i in (1..=(vlen / 2)).rev() {    
            ret.bubble_down(i);
        };

        ret

    }

    fn bubble_up(& mut self, mut ix: usize) {

        while ix > 1 {

            let parent = ix/2;

            if self.storage[parent] <= self.storage[ix] {
                break;
            }

            self.storage.swap(parent, ix);
            ix = parent;

        };

    }

    fn bubble_down(& mut self, mut ix: usize) {

        while 2 * ix < self.storage.len() {

            let mut s = 2 * ix;
            if ((s + 1) < self.storage.len()) && ( self.storage[s+1] < self.storage[s] ) {

                s = s + 1;

            }

            if self.storage[ix] < self.storage[s] {
                break;
            }

            self.storage.swap(s, ix);

            ix = s;

        }

    }

    /// Remove the minimum from the collection and return it
    pub fn extract_min(& mut self) -> Option<i32> {
        
        if self.storage.len() > 1 {
        
            let ret = self.storage[1];
            let last = self.storage.pop().unwrap();
            
            if self.storage.len() > 1 {
                self.storage[1] = last;
                self.bubble_down(1);
            }

            Some(ret)
        
        } else {
            None
        }

    }

    // Insert into the heap
    pub fn insert(& mut self, item: i32) {

        self.storage.push(item);
        self.bubble_up( self.storage.len() - 1 );

    }

    // Get the amount of items inside the heap
    pub fn size(&self) -> usize {

        self.storage.len() - 1

    }

}
