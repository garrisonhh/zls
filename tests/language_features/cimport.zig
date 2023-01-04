const std = @import("std");
const zls = @import("zls");

const Ast = std.zig.Ast;

const translate_c = zls.translate_c;

const allocator: std.mem.Allocator = std.testing.allocator;

test "convertCInclude - empty" {
    try testConvertCInclude("@cImport()", "");
    try testConvertCInclude("@cImport({})", "");
    try testConvertCInclude("@cImport({{}, {}})", "");
}

test "convertCInclude - cInclude" {
    try testConvertCInclude(
        \\@cImport(@cInclude("foo.zig"))
    ,
        \\#include <foo.zig>
    );

    try testConvertCInclude(
        \\@cImport(@cInclude("foo.zig"), @cInclude("bar.zig"))
    ,
        \\#include <foo.zig>
        \\#include <bar.zig>
    );
}

test "translate_c - cDefine" {
    try testConvertCInclude(
        \\@cImport(@cDefine("FOO", "BAR"))
    ,
        \\#define FOO BAR
    );
    try testConvertCInclude(
        \\@cImport(@cDefine("FOO", {}))
    ,
        \\#define FOO
    );
}

test "translate_c - cUndef" {
    try testConvertCInclude(
        \\@cImport(@cUndef("FOO"))
    ,
        \\#undef FOO
    );
}

fn testConvertCInclude(cimport_source: []const u8, expected: []const u8) !void {
    const source: [:0]u8 = try std.fmt.allocPrintZ(allocator, "const c = {s};", .{cimport_source});
    defer allocator.free(source);

    var ast = try std.zig.parse(allocator, source);
    defer ast.deinit(allocator);

    const main_tokens = ast.nodes.items(.main_token);

    const node: Ast.Node.Index = blk: {
        for (ast.nodes.items(.tag)) |tag, index| {
            switch (tag) {
                .builtin_call_two,
                .builtin_call_two_comma,
                .builtin_call,
                .builtin_call_comma,
                => {},
                else => continue,
            }

            if (!std.mem.eql(u8, ast.tokenSlice(main_tokens[index]), "@cImport")) continue;

            break :blk @intCast(Ast.Node.Index, index);
        }
        return error.TestUnexpectedResult; // source doesn't contain a cImport
    };

    const output = try translate_c.convertCInclude(allocator, ast, node);
    defer allocator.free(output);

    const trimmed_output = std.mem.trimRight(u8, output, &.{'\n'});

    try std.testing.expectEqualStrings(expected, trimmed_output);
}
