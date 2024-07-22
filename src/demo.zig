const std = @import("std");
const print = std.debug.print;
const Fsm = @import("fsm.zig").Fsm;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const content = "pedram";

    const fsm = try Fsm.init(allocator, content[0..]);
    defer fsm.deinit();

    fsm.process();
    for (fsm.result.items) |unit| {
        print("{?c}\t{s}\n", .{ unit.value, @tagName(unit.token) });
    }
}
