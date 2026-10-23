const std = @import("std");

pub fn printArray(comptime T: type, arr: []T) void {
    for (0..arr.len) |i| {
        std.debug.print("{any} ", .{arr[i]});
    }
    std.debug.print("\n", .{});
}

