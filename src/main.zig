const std = @import("std");
const io = std.io;
const process = std.process;
const mem = std.mem;
const http = std.http;
const json = std.json;
const math = std.math;
const Uri = std.Uri;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;

const OllamaResponse = struct {
    model: []const u8,
    created_at: []const u8,
    response: []const u8,
    done: bool,
    context: []u64,
    total_duration: u128,
    load_duration: u128,
    prompt_eval_count: u64,
    prompt_eval_duration: u128,
    eval_count: u64,
    eval_duration: u64,

    const Self = @This();

    pub fn init(value: json.Value) Self {
        return Self{
            .model = value.object.get("model").?.string,
            .created_at = value.object.get("created_at").?.string,
            .response = value.object.get("response").?.string,
            .done = value.object.get("done").?.bool,
            .context = value.object.get("context").?.array,
            .total_duration = value.object.get("total_duration").?,
            .load_duration = value.object.get("load_duration").?,
            .prompt_eval_count = value.object.get("prompt_eval_count").?,
            .prompt_eval_duration = value.object.get("prompt_eval_duration").?,
            .eval_count = value.object.get("eval_count").?,
            .eval_duration = value.object.get("eval_duration").?,
        };
    }
};

pub fn main() !void {
    const stdout = io.getStdOut().writer();
    var gpa = GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);
    const options = args[1..];

    if (options.len == 0) {
        process.exit(0);
    }

    const prompt = try std.mem.join(
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

    // const results = OllamaResponse.init(parsed);

    try stdout.print(
        \\ {any}
        \\
    , .{parsed.value.object.get("context").?.array.items});
}
