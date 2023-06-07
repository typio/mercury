const std = @import("std");

pub fn build(b: *std.Build) void {
    const zig_cli_module = b.addModule("zig_cli", .{ .source_file = .{ .path = "libs/zig-cli/src/main.zig" } });

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const client_exe = b.addExecutable(.{
        .name = "client",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "client/src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    client_exe.addModule("zig_cli", zig_cli_module);
    b.installArtifact(client_exe);

    const server_exe = b.addExecutable(.{
        .name = "server",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "server/src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    server_exe.addModule("zig_cli", zig_cli_module);
    b.installArtifact(server_exe);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    // const unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_unit_tests.step);
}
