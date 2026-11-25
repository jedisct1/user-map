const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;
    const cwd = std.Io.Dir.cwd();

    var source_files = try cwd.openDir(io, "people", .{ .iterate = true });
    defer source_files.close(io);

    var buffer: std.Io.Writer.Allocating = .init(allocator);
    defer buffer.deinit();
    const writer = &buffer.writer;
    try writer.writeAll("[");

    var first = true;
    var iter = source_files.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) return error.InvalidFile;

        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const contents = try source_files.readFileAlloc(io, entry.name, arena.allocator(), .limited(1024));
        const tree = try std.json.parseFromSlice(std.json.Value, arena.allocator(), contents, .{});

        if (!first) try writer.writeAll(",");
        first = false;
        try std.json.Stringify.value(tree.value, .{}, writer);
    }
    try writer.writeAll("]");

    try cwd.writeFile(io, .{ .sub_path = "website/users.json", .data = buffer.written() });
}
