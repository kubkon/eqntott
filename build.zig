const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const opt = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "eqntott-lib",
        .target = target,
        .optimize = opt,
    });
    lib.addIncludePath("include");
    lib.addCSourceFiles(sources, &[_][]const u8{
        "-std=gnu89",
        "-Wno-incompatible-function-pointer-types",
    });
    lib.installHeadersDirectory("include", "");
    lib.linkLibC();
    b.installArtifact(lib);

    {
        const exe = b.addExecutable(.{
            .name = "eqntott",
            .target = target,
            .optimize = opt,
        });
        exe.addCSourceFile("eqntott/main.c", &[_][]const u8{"-std=gnu89"});
        exe.linkLibrary(lib);
        exe.linkLibC();
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-eqntott", "Run example program parser");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "eqntott-zig",
            .root_source_file = .{ .path = "eqntott/eqntott.zig" },
            .target = target,
            .optimize = opt,
        });
        exe.linkLibrary(lib);
        exe.linkLibC();
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-zig-eqntott", "Run example program parser");
        run_step.dependOn(&run_cmd.step);
    }
}

const sources: []const []const u8 = &.{
    "src/bnode.c",
    "src/canon.c",
    "src/cover.c",
    "src/duple.c",
    "src/hash.c",
    "src/merge.c",
    "src/misc.c",
    "src/nt.c",
    "src/preprocess.c",
    "src/prexpr.c",
    "src/procargs.c",
    "src/pterm.c",
    "src/pterm_ops.c",
    "src/putpla.c",
    "src/read_ones.c",
    "src/reduce.c",
    "src/rmcvd.c",
    "src/substitute.c",
    "src/version.c",
    "src/yystuff.c",
    "src/y_tab.c",
};
