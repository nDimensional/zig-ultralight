# zig-ultralight

Zig bindings for [Ultralight](https://ultralig.ht/), an embedded high-performance HTML renderer.

Built and tested with Zig version `0.13.0`.

## Usage

First, [download the Ultralight v1.4.0-beta SDK](https://github.com/ultralight-ux/Ultralight/releases/tag/v1.4.0-beta) for your platform.

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
const ultralight = b.dependency("ultralight", .{ .SDK = @as([]const u8, "SDK") });
app.root_module.addImport("ul", ultralight.module("ul"));
```

See the [example](example.zig) for API usage.
