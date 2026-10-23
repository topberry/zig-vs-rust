const std = @import("std");
const ds = @import("ds.zig");
const Allocator = std.mem.Allocator;

/// generic Node of a binary tree
pub fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        parent: ?*Self = null,
        left: ?*Self = null,
        right: ?*Self = null,
        value: T,
    };
}

pub fn SplayTree(comptime T: type) type {
    return struct {
        root: ?*Node(T),
        pool: std.heap.MemoryPool(Node(T)),

        const Self = @This();

        pub const empty: Self = .{.root = null, .pool = .empty};

        pub fn deinit(self: *Self, alc: Allocator) void {
            self.pool.deinit(alc);
        }

        fn rotation_L(x: *Node(T)) void {
            const y = x.parent.?;
            const beta = x.right;
            x.parent = y.parent;
            y.parent = x;
            x.right = y;
            y.left = beta;
            if (beta) |b| {
                b.parent = y;
            }
        }

        fn rotation_R(x: *Node(T)) void {
            const y = x.parent.?;
            const beta = x.left;
            x.parent = y.parent;
            y.parent = x;
            x.left = y;
            y.right = beta;
            if (beta) |b| {
                b.parent = y;
            }
        }

        fn splay(self: *Self, start_pos: *Node(T)) void {
            const current = start_pos;
            var parent = start_pos.parent;
            while (parent != null) {
                const grandparent = parent.?.parent;
                if (grandparent == null) { // do one rotation if no double is possible
                    if (parent.?.value > current.value) {
                        // do L rotation
                        rotation_L(current);
                    } else {
                        // do R rotation
                        rotation_R(current);
                    }
                    break;
                }

                // do double routations while possible
                const is_parent_left = grandparent.?.left == parent.?;
                const is_current_left = parent.?.left == current;
                if (is_parent_left) {
                    if (is_current_left) {
                        // do LL rotation
                        rotation_L(parent.?);
                        rotation_L(current);
                    } else {
                        // do LR rotation
                        rotation_R(current);
                        rotation_L(current);
                    }
                } else {
                    if (is_current_left) {
                        // do RL rotation
                        rotation_L(current);
                        rotation_R(current);
                    } else {
                        // do RR rotation
                        rotation_R(parent.?);
                        rotation_R(current);
                    }
                }
                parent = current.parent;
            }
            self.root = current;
        }

        pub fn insert(self: *Self, alc: Allocator, value: T) !void {
            var current: ?*Node(T) = null;
            var next = self.root;

            while (next != null) {
                current = next;
                if (current.?.value < value) {
                    next = current.?.right;
                } else if (current.?.value > value) {
                    next = current.?.left;
                } else {
                    return error.KeyExists;
                }
            }
            const new_node = try self.pool.create(alc);
            new_node.* = .{
                .value = value,
                .parent = current,
            };
            if (current == null) { self.root = new_node; return; } 
            if (current.?.value < value) { 
                current.?.right = new_node;
            } else {
                current.?.left = new_node;
            }

            // splay
            splay(self, new_node);
        }

        pub fn find(self: *Self, value: T) ?*Node(T) {
            var current: ?*Node(T) = null;
            var next = self.root;

            while (next != null) {
                current = next;
                if (current.?.value < value) {
                    next = current.?.right;
                } else if (current.?.value > value) {
                    next = current.?.left;
                } else {
                    break;
                }
            }

            if (current == null) { return null; } 
            if (next == null) {
                splay(self, current.?);
                return null;
            }
            splay(self, next.?);
            return next;
        }

        pub fn delete(self: *Self, value: T) !void {
            if (self.root == null) { return error.KeyNonExists; }

            // find and splay to top
            const ind = self.find(value);
            if (ind == null) { return error.KeyNonExists; }

            // disect into two subtrees
            const left_subtree = self.root.?.left;
            const right_subtree = self.root.?.right;
            if (left_subtree == null) { self.pool.destroy(self.root.?); self.root = right_subtree; if (right_subtree) |sub| {sub.parent = null; } return; }
            left_subtree.?.parent = null;

            // find max in left subtree and splay
            const max_val = self.root.?.value;
            self.pool.destroy(self.root.?);
            self.root = left_subtree;
            _ = self.find(max_val);

            // join over right
            self.root.?.right = right_subtree;
            if (right_subtree) |sub| {
                sub.parent = self.root;
            }
        }

        pub fn print(self: *Self) void {
            printTree(self.root, 0);
        }

        pub fn printTree(node: ?*Node(T), depth: usize) void {
            for (0..depth) |_| {
                std.debug.print("|", .{});
            }
            if (node == null) {
                std.debug.print("-> \n", .{});
                return;
            }
            std.debug.print("-> {d}\n", .{node.?.value});
            printTree(node.?.left, depth + 1);

            for (0..depth+1) |_| {
                std.debug.print("|", .{});
            }
            std.debug.print("\n", .{});
            printTree(node.?.right, depth + 1);
        }
    };
}

const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
test "splay trees base test" {
    const alc = std.testing.allocator;

    var st: SplayTree(u32) = .empty;
    defer st.deinit(alc);

    try st.insert(alc, 42);
    try st.insert(alc, 21);
    try st.insert(alc, 10);
    try expectError(error.KeyExists, st.insert(alc, 42));
    try st.insert(alc, 15);
    try expectEqual(st.root, st.find(15).?);
    try expectEqual(null, st.find(64));
    try st.delete(42);
    try st.delete(21);
    try expectError(error.KeyNonExists, st.delete(64));
}

