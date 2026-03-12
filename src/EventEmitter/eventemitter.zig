const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn EventEmitter(comptime Payload: type) type {
    return struct {
        const Self = @This();
        const Handler = *const fn (Payload) void;
        const HandlerList = std.ArrayListUnmanaged(Handler);
        const EventMap = std.StringArrayHashMapUnmanaged(HandlerList);

        allocator: Allocator,
        subscribers: EventMap,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .allocator = allocator,
                .subscribers = .{},
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.subscribers.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.deinit(self.allocator);
                self.allocator.free(entry.key_ptr.*);
            }
            self.subscribers.deinit(self.allocator);
        }

        pub fn on(self: *Self, event: []const u8, handler: Handler) !void {
            const gop = try self.subscribers.getOrPut(self.allocator, event);
            if (!gop.found_existing) {
                gop.key_ptr.* = try self.allocator.dupe(u8, event);
                gop.value_ptr.* = .{};
            }
            try gop.value_ptr.append(self.allocator, handler);
        }

        pub fn off(self: *Self, event: []const u8, handler: Handler) void {
            if (self.subscribers.get(event)) |list| {
                for (list.items, 0..) |h, i| {
                    if (h == handler) {
                        _ = list.orderedRemove(i);
                        return;
                    }
                }
            }
        }

        pub fn emit(self: *Self, event: []const u8, payload: Payload) void {
            if (self.subscribers.get(event)) |list| {
                for (list.items) |handler| {
                    handler(payload);
                }
            }
            if (self.subscribers.get("*")) |list| {
                for (list.items) |handler| {
                    handler(payload);
                }
            }
        }
    };
}

test "basic emit" {
    const Event = struct { id: []const u8 };
    var emitter = EventEmitter(Event).init(std.testing.allocator);
    defer emitter.deinit();

    const handler = struct {
        fn handler(e: Event) void {
            _ = e;
        }
    }.handler;

    try emitter.on("test", handler);
    emitter.emit("test", .{ .id = "1" });
}
