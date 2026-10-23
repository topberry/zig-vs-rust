const std = @import("std");

const Stack = struct {
    size: u8 = 0,
    used: u8 = 0,
    pointer: [*]u8 = undefined,
    allocator: std.mem.Allocator = undefined,

    pub fn init(alc: std.mem.Allocator) !Stack {
        return Stack {
            .pointer = (try alc.alloc(u8, 1)).ptr,
            .size = 1,
            .allocator = alc,
        };
    }

    pub fn deinit(self: *Stack) void {
        self.allocator.free(self.pointer[0..self.size]);
    }

    pub fn push(self: *Stack, item: u8) !void {
        if (self.used == self.size) {
            const old_size = self.size;
            const old_pointer = self.pointer;
            self.size = self.size * 2;
            self.pointer = (try self.allocator.alloc(u8, self.size)).ptr;
            for (0..self.used) |i| {
                self.pointer[i] = old_pointer[i];
            }
            self.allocator.free(old_pointer[0..old_size]);
        }
        self.pointer[self.used] = item;
        self.used += 1;
        return;
    }

    pub fn pop(self: *Stack) !u8 {
        if (self.used == 0) {
            return error.EmptyStack;
        }
        self.used -= 1;
        return self.pointer[self.used];
    }
};

pub fn main(_: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    var s = try Stack.init(alc);
    defer s.deinit();
    // test data
    try s.push(8);
    try s.push(7);
    try s.push(4);
    std.debug.print("{d}\n", .{try s.pop()});
    std.debug.print("{d}\n", .{try s.pop()});
    try s.push(5);
    std.debug.print("{d}\n", .{try s.pop()});
}

