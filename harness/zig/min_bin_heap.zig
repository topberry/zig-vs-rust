const std = @import("std");
const Io = std.Io;
const ds = @import("ds");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var heap = try ds.MinBinHeap(i64).init(gpa);
    defer heap.deinit(gpa);

    var in_buf: [4096]u8 = undefined;
    var stdin_reader = Io.File.stdin().reader(io, &in_buf);
    const reader = &stdin_reader.interface;

    var out_buf: [4096]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &out_buf);
    const writer = &stdout_writer.interface;

    while (true) {
        const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            error.StreamTooLong => {
                _ = reader.discardDelimiterInclusive('\n') catch {};
                return error.BadInput;
            },
            else => |e| return e,
        };
        // consume the newline if present
        if (reader.bufferedLen() > 0 and reader.buffered()[0] == '\n') reader.toss(1);

        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0 or trimmed[0] == '#') continue;

        var parts = std.mem.tokenizeAny(u8, trimmed, " \t");
        const op = parts.next() orelse return error.BadInput;

        if (std.mem.eql(u8, op, "I")) {
            const arg = parts.next() orelse return error.BadInput;
            const v = try std.fmt.parseInt(i64, arg, 10);
            try heap.insert(gpa, v);
        } else if (std.mem.eql(u8, op, "E")) {
            const got = try heap.extractMin();
            if (got) |v| {
                try writer.print("{d}\n", .{v});
            } else {
                try writer.writeAll("-\n");
            }
        } else {
            return error.UnknownOp;
        }
    }

    try writer.flush();
}
