const std = @import("std");
const ds = @import("ds.zig");
const Allocator = std.mem.Allocator;
const graph = @import("graph.zig");
const UGraph = graph.UGraph;

/// bfs(G - input graph, s_id - start vertex id, t_id - target vertex id)
/// returns length of the shortest path from s_id to t_id
pub fn bfs(alc: Allocator, g: UGraph, s_id: u32, t_id: u32) !u32 {
    if (s_id == t_id) {
        return 0;
    }

    // init queue
    var q = try ds.Queue([2]u32).init(alc);
    defer q.deinit(alc);
    try q.push(alc, .{s_id, 0});

    // init visited
    var visited = try alc.alloc(bool, g.n);
    defer alc.free(visited);
    @memset(visited, false);
    visited[s_id] = true;

    while (q.pop()) |cs| {
        const current, const steps = cs;
        for (g.get_neighbours(current)) |u| {
            if (!visited[u]) {
                if (u == t_id) { return steps + 1; }
                visited[u] = true;
                try q.push(alc, .{u, steps + 1});
            }
        }
    }

    return error.NoPath;
}

const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
test "testing bfs on simple graph" {
    const alc = std.testing.allocator;

    const g = try UGraph.init(alc, 5, 4, &[_]u32{0, 1, 1, 2, 1, 3, 2, 3});
    defer g.deinit(alc);

    try expectEqual(bfs(alc, g, 0, 3), 2);
    try expectError(error.NoPath, bfs(alc, g, 0, 4));
}

