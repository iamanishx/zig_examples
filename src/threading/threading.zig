const std = @import("std");

const SharedCounter = struct {
    value: u64,
    mutex: std.Thread.Mutex,

    pub fn init() SharedCounter {
        return .{
            .value = 0,
            .mutex = .{},
        };
    }

    pub fn increment(self: *SharedCounter) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.value += 1;
    }
};

const WorkerArgs = struct {
    id: usize,
    counter: *SharedCounter,
    atomic_counter: *std.atomic.Value(u64),
    wg: *std.Thread.WaitGroup,
    iterations: usize,
};

fn worker(args: WorkerArgs) void {
    defer args.wg.finish();

    std.debug.print("[thread {d}] started\n", .{args.id});

    for (0..args.iterations) |_| {
        args.counter.increment();

        _ = args.atomic_counter.fetchAdd(1, .monotonic);
    }

    std.debug.print("[thread {d}] done\n", .{args.id});
}

const PoolTaskArgs = struct {
    id: usize,
    counter: *std.atomic.Value(u64),
};

fn poolTask(args: PoolTaskArgs) void {
    _ = args.counter.fetchAdd(1, .monotonic);
    std.debug.print("[pool task {d}] ran\n", .{args.id});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const thread_count = 4;
    const iterations = 100;

    var counter = SharedCounter.init();
    var atomic_counter = std.atomic.Value(u64).init(0);
    var wg = std.Thread.WaitGroup{};

    var threads: [thread_count]std.Thread = undefined;

    for (0..thread_count) |i| {
        wg.start();
        const args = WorkerArgs{
            .id = i,
            .counter = &counter,
            .atomic_counter = &atomic_counter,
            .wg = &wg,
            .iterations = iterations,
        };
        threads[i] = try std.Thread.spawn(.{}, worker, .{args});
    }

    wg.wait();

    for (threads) |t| t.join();

    const expected: u64 = thread_count * iterations;
    std.debug.print("\n--- Results ---\n", .{});
    std.debug.print("Expected     : {d}\n", .{expected});
    std.debug.print("Mutex counter: {d}\n", .{counter.value});
    std.debug.print("Atomic counter: {d}\n", .{atomic_counter.load(.monotonic)});

    std.debug.print("\n--- Thread Pool ---\n", .{});

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator, .n_jobs = 2 });

    var pool_counter = std.atomic.Value(u64).init(0);

    for (0..8) |i| {
        const task_args = PoolTaskArgs{ .id = i, .counter = &pool_counter };
        try pool.spawn(poolTask, .{task_args});
    }

    pool.deinit();

    std.debug.print("Pool tasks completed: {d}\n", .{pool_counter.load(.monotonic)});
}
