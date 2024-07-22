const std = @import("std");
const Fsm = @import("fsm.zig").Fsm;
const Tokens = @import("tokens.zig").Tokens;

test "process" {
    const content = "hello";
    const allocator = std.testing.allocator;
    const fsm = try Fsm.init(allocator, content[0..]);
    fsm.process();
    defer fsm.deinit();

    try std.testing.expect(fsm.result.items.len == 5);
}

test "string" {
    const content = "hello";
    const allocator = std.testing.allocator;
    const fsm = try Fsm.init(allocator, content[0..]);
    fsm.process();
    defer fsm.deinit();

    try std.testing.expect(fsm.result.items[0].value == 'h');
    try std.testing.expect(fsm.result.items[0].token == Tokens.string);
    try std.testing.expect(fsm.result.items[4].value == 'o');
    try std.testing.expect(fsm.result.items[4].token == Tokens.string);
}
