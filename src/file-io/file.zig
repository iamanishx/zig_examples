const std = @import("std");

const f = std.fs.cwd();

pub fn openFile()!void{
    const file = try f.openFile("test.txt", .{
        .mode = .read_write,
    });
    defer file.close();
}

pub fn createFile()!void{
    const file = try f.createFile("test.txt", .{});
    defer file.close();
}

pub fn readEntireFile(allocator: std.mem.Allocator) ![]u8 {
    const contents = try f.readFile("input.txt", allocator); //here it dynamically allocates memory according to the file size
    defer allocator.free(contents);
    return contents;
}

pub fn writeEntireFile(contents: []const u8) !void {
    const file = try f.createFile("output.txt", .{});
    defer file.close();
    try file.writeAll(contents);
}

pub fn BufferedCopy(
    allocator: std.mem.Allocator,
    source_path: []const u8,
    dest_path: []const u8,
) !void {
    const src = try f.openFile(source_path, .{
        .mode = .read_only,
    });
    defer src.close();

    const dst = try f.createFile(dest_path, .{
        .truncate = true,
    });
    defer dst.close();

    var buf_writer = std.io.bufferedWriter(dst.writer());
    const writer = buf_writer.writer();

    const chunk_size = 64 * 1024; // 64KB
    var buffer = try allocator.alloc(u8, chunk_size);
    defer allocator.free(buffer);

    var total_written: u64 = 0;

    while (true) {
        const bytes_read = try src.read(buffer);
        if (bytes_read == 0) break;

        try writer.writeAll(buffer[0..bytes_read]);
        total_written += bytes_read;
    }

    try buf_writer.flush();

    std.debug.print("Copied {d} bytes\n", .{total_written});
}

pub fn getMetadata() !void {
    const file = try f.openFile("test.txt", .{});
    defer file.close();

    const stat = try file.stat();
    std.debug.print("Size: {d}\n", .{stat.size});
    std.debug.print("Mode: {o}\n", .{stat.mode});
}
