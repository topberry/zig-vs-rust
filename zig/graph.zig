const std = @import("std");
const Allocator = std.mem.Allocator;

/// undirected graph
/// memory friendly for sparse graphs (list of neighbours)
pub const UGraph = struct {
    n: usize = 0,
    m: usize = 0,
    fid: []usize = undefined,
    neighbours: []u32 = undefined,

    const Self = @This();

    pub fn init(
                alc: Allocator,
                v_num: usize,
                e_num: usize,
                edges_list: []const u32
            ) !Self {
        var fid = try alc.alloc(usize, v_num+1);
        @memset(fid, 0);
        // get number of neighbours
        var i: usize = 0;
        while (i < 2*e_num) : (i += 2) {
            const u, const v = .{edges_list[i], edges_list[i+1]};
            fid[u+1] += 1;
            fid[v+1] += 1;
        }
        // set correct first indices
        for (2..v_num+1) |_i| {
            fid[_i] += fid[_i - 1]; 
        }
        // load neighbours
        var pos = try alc.alloc(usize, v_num);
        @memset(pos, 0);
        defer alc.free(pos);
        var ngh = try alc.alloc(u32, e_num*2);
        i = 0;
        while (i < 2*e_num) : (i += 2) {
            const u, const v = .{edges_list[i], edges_list[i+1]};
            ngh[fid[u] + pos[u]] = v;
            pos[u] += 1;
            ngh[fid[v] + pos[v]] = u;
            pos[v] += 1;
        }

        return Self {
            .n = v_num,
            .m = e_num,
            .fid = fid,
            .neighbours = ngh,
        };
    }

    pub fn deinit(self: Self, alc: Allocator) void {
        alc.free(self.fid);
        alc.free(self.neighbours);
    }

    pub fn get_neighbours(self: Self, v: u32) []u32 {
        return self.neighbours[self.fid[v]..self.fid[v+1]];
    }

    pub fn print(self: Self) void {
        std.debug.print("|V| = {d}, |E| = {d}\n", .{self.n, self.m});
        for (0..self.n) |v| {
            std.debug.print("{d}:", .{v});
            for (0..self.fid[v+1]-self.fid[v]) |pos| {
                std.debug.print(" {d}", .{self.neighbours[self.fid[v] + pos]});
            }
            std.debug.print("\n", .{});
        }
    }
};

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectError = std.testing.expectError;
test "testing graph struct" {
    const alc = std.testing.allocator;

    const g = try UGraph.init(alc, 4, 4, &[_]u32{0, 1, 1, 2, 1, 3, 2, 3});
    defer g.deinit(alc);

    g.print();
    try expectEqualSlices(u32, g.get_neighbours(2), &[_]u32{1, 3});
}
