const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Vec(comptime T: type) type {
    return struct {
        used: usize = 0,
        array_list: []T,

        pub const empty: Vec(T) = .{ .array_list = &.{}};

        pub fn initCap(alc: Allocator, n: usize) !Vec(T) {
            return Vec(T){ .array_list = try alc.alloc(T, n) };
        }

        pub fn deinit(self: *Vec(T), alc: Allocator) void {
            alc.free(self.array_list);
        }

        pub fn push(self: *Vec(T), alc: Allocator, item: T) !void {
            if (self.used == self.array_list.len) {
                const new_capacity = if (self.array_list.len == 0) 8 else self.array_list.len * 2;
                self.array_list = try alc.realloc(self.array_list, new_capacity);
            }
            self.array_list[self.used] = item;
            self.used += 1;
            return;
        }

        pub fn get(self: Vec(T), index: usize) T {
            if (index >= self.used) {
                unreachable;
            }
            return self.array_list[index];
        }

        pub fn pop(self: *Vec(T)) ?T {
            if (self.used == 0) { return null; }
            self.used -= 1;
            return self.array_list[self.used + 1];
        }

        pub fn edit(self: *Vec(T), index: usize, new_item: T) void {
            if (index >= self.used) {
                unreachable;
            }
            self.array_list[index] = new_item;
        }

        pub fn len(self: *Vec(T)) usize {
            return self.used;
        }
    };
}

pub fn Stack(comptime T: type) type {
    return struct {
        used: usize = 0,
        stack: []T = undefined,

        pub fn init(alc: Allocator) !Stack(T) {
            return Stack(T) {
                .stack = try alc.alloc(T, 1),
            };
        }

        pub fn deinit(self: *Stack(T), alc: Allocator) void {
            alc.free(self.stack);
        }

        pub fn push(self: *Stack(T), alc: Allocator, item: T) !void {
            if (self.used == self.stack.len) {
                self.stack = try alc.realloc(self.stack, self.stack.len * 2);
            }
            self.stack[self.used] = item;
            self.used += 1;
            return;
        }

        pub fn pop(self: *Stack(T)) ?T {
            if (self.used == 0) {
                return null;
            }
            self.used -= 1;
            return self.stack[self.used];
        }
    };
}

pub fn Queue(comptime T: type) type {
    return struct {
        head: usize = 0,
        tail: usize = 0,
        ring: []T = undefined,

        pub fn init(alc: Allocator) !Queue(T) {
            return Queue(T) {
                .ring = try alc.alloc(T, 2),
            };
        }

        pub fn deinit(self: *Queue(T), alc: Allocator) void {
            alc.free(self.ring);
        }

        pub fn print(self: *Queue(T)) void {
            for (0..self.ring.len) |i| {
                std.debug.print("{d} ", .{self.ring[i]});
            }
            std.debug.print("\n", .{});
        }

        pub fn push(self: *Queue(T), alc: Allocator, item: T) !void {
            self.ring[self.tail] = item;
            self.tail = (self.tail + 1) % self.ring.len;
            if (self.tail == self.head) {
                const old_len = self.ring.len;
                self.ring = try alc.realloc(self.ring, self.ring.len * 2);
                @memcpy(self.ring[self.head+old_len..self.ring.len], self.ring[self.head..old_len]);
                self.head = self.head + old_len;
            }
            return;
        }

        pub fn pop(self: *Queue(T)) ?T {
            if (self.head == self.tail) {
                return null;
            }
            const x = self.ring[self.head];
            self.head = (self.head + 1) % self.ring.len;
            return x;
        }

        pub fn empty(self: *Queue(T)) bool {
            return self.head == self.tail;
        }
    };
}

const prnt = @import("print.zig");
pub fn MinBinHeap(comptime T: type) type {
    return struct {
        head: usize,
        data: Vec(T),

        const Self = @This();

        pub fn init(alc: Allocator) !Self {
            var self: Self = .{
                .data = .empty,
                .head = 1,
            };
            try self.data.push(alc, undefined);
            return self;
        }

        pub fn deinit(self: *Self, alc: Allocator) void {
            self.data.deinit(alc);
        }

        pub fn insert(self: *Self, alc: Allocator, item: T) !void {
            try self.data.push(alc, item);
            var current = self.head;
            var next = current / 2;
            self.head += 1;
            while (next != 0 and self.data.get(next) > item) {
                // swap
                self.data.edit(current, self.data.get(next));
                current = next;
                next = next / 2;
            }
            self.data.edit(current, item);
        }

        pub fn extractMin(self: *Self) !?T {
            if (self.head == 1) { return null; }
            const ret_value = self.data.get(1);
            const new_root = self.data.get(self.head - 1);
            self.head -= 1; // delete last item
            _ = self.data.pop();
            if (self.head == 1) { return ret_value; }
            self.data.edit(1, new_root);
            var current: usize = 1;
            const current_val = self.data.get(current);
            while (2 * current < self.head) {
                // get indices
                const left_ind = 2 * current;
                const right_ind = current * 2 + 1;

                // get values
                var min_val = self.data.get(left_ind);
                var min_id = left_ind;
                if (right_ind < self.head and self.data.get(right_ind) < min_val) { min_val = self.data.get(right_ind); min_id = right_ind; }

                // check if swap
                if (current_val <= min_val) { break; }

                // swap
                self.data.edit(current, min_val);

                current = min_id;
            }
            self.data.edit(current, current_val);
            return ret_value;
        }
    };
}



const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

test "testing vec usage" {
    const alc = std.testing.allocator;

    var s = Vec(u8).empty;
    defer s.deinit(alc);

    // data
    try s.push(alc, 8);
    try s.push(alc, 7);
    try s.push(alc, 4);

    try expectEqual(@as(u8, 4), s.get(2));
    try expectEqual(@as(u8, 7), s.get(1));

    try s.push(alc, 5);

    try expectEqual(@as(u8, 5), s.get(3));
    try expectEqual(@as(u8, 8), s.get(0));
}

test "testing stack usage" {
    const alc = std.testing.allocator;

    var s = try Stack(u8).init(alc);
    defer s.deinit(alc);

    // data
    try s.push(alc, 8);
    try s.push(alc, 7);
    try s.push(alc, 4);

    try expectEqual(@as(u8, 4), s.pop());
    try expectEqual(@as(u8, 7), s.pop());

    try s.push(alc, 5);

    try expectEqual(@as(u8, 5), s.pop());
    try expectEqual(@as(u8, 8), s.pop());
    try expectEqual(null, s.pop());
}

test "testing queue usage" {
    const alc = std.testing.allocator;

    var q = try Queue(u8).init(alc);
    defer q.deinit(alc);

    // data
    try q.push(alc, 8);
    try q.push(alc, 7);
    try q.push(alc, 4);

    try expectEqual(@as(u8, 8), q.pop());
    try expectEqual(@as(u8, 7), q.pop());

    try q.push(alc, 5);

    try expectEqual(@as(u8, 4), q.pop());
    try expectEqual(@as(u8, 5), q.pop());
    try expectEqual(null, q.pop());
}

test "testing MinBinHeap usage" {
    const alc = std.testing.allocator;

    var h = try MinBinHeap(u8).init(alc);
    defer h.deinit(alc);

    // data
    try h.insert(alc, 8);
    try h.insert(alc, 7);
    try h.insert(alc, 10);
    try h.insert(alc, 4);
    try h.insert(alc, 12);

    try expectEqual(@as(u8, 4), try h.extractMin());
    try expectEqual(@as(u8, 7), try h.extractMin());

    try h.insert(alc, 5);

    try expectEqual(@as(u8, 5), try h.extractMin());
    try expectEqual(@as(u8, 8), try h.extractMin());
    try expectEqual(@as(u8, 10), try h.extractMin());
    try expectEqual(@as(u8, 12), try h.extractMin());
    try expectEqual(null, try h.extractMin());
}

