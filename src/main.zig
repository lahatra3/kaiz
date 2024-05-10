const std = @import("std");
const io = std.io;
const process = std.process;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;

pub fn main() !void {
    const stdout = io.getStdOut().writer();
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);
    const options = args[1..];

    if (options.len == 0) {
        return;
    }

    try stdout.print(
        \\ OPTIONS: {s}
        \\
    , .{options});
}
