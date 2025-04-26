# zig-ultralight

Zig bindings for [Ultralight](https://ultralig.ht/), an embedded high-performance HTML renderer.

Built and tested with Zig version `0.14.0`.

## Usage

First, [download the Ultralight v1.4.0 SDK](https://ultralig.ht/download) for your platform.

Then, add zig-ultralight to `build.zig.zon`:

```
.{
    .dependencies = .{
        .ultralight = .{
            .url = "https://github.com/nDimensional/zig-ultralight/archive/$COMMIT.tar.gz",
            // .hash = "...",
        },
    },
}
```

Then add the `ul` import to your root modules in `build.zig`, passing the path to the Ultralight SDK as a build argument:

```zig
const ultralight = b.dependency("ultralight", .{
    .SDK = @as([]const u8, "path/to/sdk/folder"),
});
app.root_module.addImport("ul", ultralight.module("ul"));
```

To run the example [example](example.zig), pass the SDK path in usind `-DSDK` from the CLI:

```
$ zig build run -DSDK=path/to/sdk/folder
```
