const std = @import("std");
const LazyPath = std.Build.LazyPath;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sdk = b.option([]const u8, "SDK", "Path to Ultralight SDK") orelse "SDK";

    const sdk_bin = try std.fs.path.join(b.allocator, &.{ sdk, "bin" });
    defer b.allocator.free(sdk_bin);

    const sdk_include = try std.fs.path.join(b.allocator, &.{ sdk, "include" });
    defer b.allocator.free(sdk_include);

    const ul = b.addModule("ul", .{
        .root_source_file = LazyPath.relative("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    ul.addRPath(.{ .cwd_relative = sdk_bin });
    ul.addLibraryPath(.{ .cwd_relative = sdk_bin });
    ul.addIncludePath(.{ .cwd_relative = sdk_include });
    ul.linkSystemLibrary("Ultralight", .{});
    ul.linkSystemLibrary("UltralightCore", .{});
    ul.linkSystemLibrary("WebCore", .{});
    ul.linkSystemLibrary("AppCore", .{});

    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = LazyPath.relative("main.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    exe.root_module.addImport("ul", ul);

    const exe_artifact = b.addRunArtifact(exe);
    b.step("run", "Run the example").dependOn(&exe_artifact.step);
}
