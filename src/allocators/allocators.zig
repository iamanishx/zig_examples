const std = @import("std");

// 1. General Purpose Allocator
pub fn usegpa() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    
    const allocator = gpa.allocator();
    
    const slice = allocator.alloc(u8, 100);
    defer allocator.free(slice);
    
    if(gpa.deinit() == .leak ){
        std.debug.print("Memory leak\n", .{});
    }
}

// with debug settings
pub fn usegpawithdebug() !void {
    var debugpa = std.heap.GeneralPurposeAllocator(.{
        .verbose_log = true,
        .safety = true,
        .thread_safe = true,
    }){};
    defer _ = debugpa.deinit();
    
    _ = debugpa.allocator();
}

//2. Arena Allocator that free all at once 

pub fn useArena() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();  // arena.deinit() frees all at once
    
    const allocator = arena.allocator();
    
    const slice = try allocator.alloc(u8, 100);
    const a = try allocator.alloc(u8, 10);
    _ = slice;
    _ = a;
}

// 3. Page Allocator (usually paired with Arena for cleanup)
pub fn usePageAllocator() !void {
    const allocator = std.heap.page_allocator;
    
    // Allocates but MUST free explicitly
    const memory = try allocator.alloc(u8, 1000);
    defer allocator.free(memory);
    
    // Usually paired with Arena for cleanup
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
}

pub fn useFixedBuffer() !void {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const slice = try allocator.alloc(u8, 100);
    defer allocator.free(slice);

    //exceed 1024 bytes, it returns error.OutOfMemory
}

// 4. C Allocator
pub fn useCAllocator() !void {
    const allocator = std.heap.c_allocator;
    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);
}