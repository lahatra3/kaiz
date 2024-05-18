const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const log = std.log;
const http = std.http;
const json = std.json;
const math = std.math;
const process = std.process;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;

pub fn main() !void {
    const stdout = io.getStdOut();

    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);
    const options = args[1..];

    if (options.len == 0) {
        process.exit(0);
    }

    const prompt = try mem.join(
        allocator,
        " ",
        options,
    );
    defer allocator.free(prompt);

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    var request_body = ArrayList(u8).init(allocator);
    defer request_body.deinit();
    try json.stringify(
        .{ .model = "kaiz", .prompt = prompt, .stream = false },
        .{ .whitespace = .minified },
        request_body.writer(),
    );

    var response_body = ArrayList(u8).init(allocator);
    defer response_body.deinit();

    _ = try client.fetch(.{
        .method = .POST,
        .payload = request_body.items,
        .location = .{
            .url = "",
        },
        .headers = .{
            .content_type = .{
                .override = "application/json; charset=utf-8",
            },
        },
        .response_storage = .{
            .dynamic = &response_body,
        },
    });

    const parsed = try json.parseFromSlice(
        json.Value,
        allocator,
        response_body.items,
        .{},
    );
    defer parsed.deinit();

    try stdout.writer().writeAll(parsed.value.object.get("response").?.string);
}
