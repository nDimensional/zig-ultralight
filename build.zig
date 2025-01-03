const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sdk = b.option([]const u8, "SDK", "Path to Ultralight SDK") orelse "SDK";

    const sdk_bin = try std.fs.path.join(b.allocator, &.{ sdk, "bin" });
    defer b.allocator.free(sdk_bin);

    const sdk_include = try std.fs.path.join(b.allocator, &.{ sdk, "include" });
    defer b.allocator.free(sdk_include);

    const ul = b.addModule("ul", .{
        .root_source_file = b.path("src/lib.zig"),
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

    const example_app = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("example.zig"),
        .target = target,
        .optimize = optimize,
    });

    example_app.root_module.addImport("ul", ul);

    const example_app_artifact = b.addRunArtifact(example_app);
    b.step("run", "Run the example app").dependOn(&example_app_artifact.step);
}
