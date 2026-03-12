const std = @import("std");
const EventEmitter = @import("eventemitter.zig").EventEmitter;

pub fn main() void {
    var buffer: [8192]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const UserEvent = struct {
        id: []const u8,
        name: []const u8,
    };

    var emitter = EventEmitter(UserEvent).init(allocator);
    defer emitter.deinit();

    emitter.on("user.created", struct {
        fn handler(event: UserEvent) void {
            std.debug.print("[user.created] id={s}, name={s}\n", .{ event.id, event.name });
        }
    }.handler) catch unreachable;

    emitter.on("user.updated", struct {
        fn handler(event: UserEvent) void {
            std.debug.print("[user.updated] id={s}, name={s}\n", .{ event.id, event.name });
        }
    }.handler) catch unreachable;

    emitter.on("*", struct {
        fn handler(event: UserEvent) void {
            std.debug.print("[wildcard] caught event for {s}\n", .{event.id});
        }
    }.handler) catch unreachable;

    std.debug.print("--- Emit user.created ---\n", .{});
    emitter.emit("user.created", .{ .id = "1", .name = "Alice" });

    std.debug.print("--- Emit user.updated ---\n", .{});
    emitter.emit("user.updated", .{ .id = "2", .name = "Bob" });

    std.debug.print("--- Done ---\n", .{});
}
