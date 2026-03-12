//Nested function are invalid in zig it only supports top-level functions and inside structs/enums/unions
// example 
// fn outer() void {
//     fn inner() void {
//     }
//     inner();
// } this is invalid 
const std = @import("std");

fn outer() void {
    const Math = struct {
        fn inner(a: i32, b: i32) i32 {
            return a + b;
        }
    };
    const result = Math.inner(2, 3);
    _ = result;
}


//------------ENUMS-------------
const Direction = enum {
    north,
    south,
    east,
    west,
};
fn move(dir: Direction) void {
    switch (dir) {
        .north => {},
        .south => {},
        .east => {},
        .west => {},
    }
}

//------------STRUCTS-------------
const User = struct {
    id: u32,
    age: u8,
};

var user = User{
    .id = 10,
    .age = 22,
};

//------------UNIONS-------------
const Result = union(enum) {
    success: i32,
    err: []const u8,
};
pub fn main() void {
    const r = Result{ .success = 10 };
    std.debug.print("{any}\n", .{r});
}