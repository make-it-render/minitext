const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const text = b.addModule(
        "minitext",
        .{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
            .strip = optimize == .ReleaseSmall,
        },
    );

    {
        const tests = b.addTest(.{
            .root_module = text,
        });

        const run_tests = b.addRunArtifact(tests);
        const run_tests_step = b.step("test", "Run tests");
        run_tests_step.dependOn(&run_tests.step);
    }

    {
        const docs = b.addObject(.{
            .name = "docs",
            .root_module = text,
        });

        const install_docs = b.addInstallDirectory(.{
            .source_dir = docs.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs",
        });

        const docs_step = b.step("docs", "Install documentation");
        docs_step.dependOn(&install_docs.step);
    }
}
