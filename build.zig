const std = @import("std");

pub fn build(b: *std.Build) void {
    const std_target = b.standardTargetOptions(.{});
    const std_optimize = b.standardOptimizeOption(.{});
    const with_demo = b.option(bool, "demo", "demo executable") orelse false;

    _ = b.addModule("zegexlib", .{
        .target = std_target,
        .optimize = std_optimize,
        .root_source_file = b.path("src/root.zig"),
    });

    const zegex = b.addSharedLibrary(.{
        .name = "zegexlib",
        .target = std_target,
        .optimize = std_optimize,
        .root_source_file = b.path("src/root.zig"),
    });

    const demo_exec = b.addExecutable(.{
        .name = "zegexlib_demo",
        .target = std_target,
        .optimize = std_optimize,
        .root_source_file = b.path("src/demo.zig"),
    });

    const test_step = b.step("test", "run tests");
    const test_comp = b.addTest(.{
        .target = std_target,
        .optimize = std_optimize,
        .root_source_file = b.path("src/test.zig"),
    });
    const run_test = b.addRunArtifact(test_comp);
    test_step.dependOn(&run_test.step);

    if (with_demo) {
        b.installArtifact(demo_exec);
        const run_demo = b.addRunArtifact(demo_exec);
        b.default_step.dependOn(&run_demo.step);
    }

    b.installArtifact(zegex);
}
