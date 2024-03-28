# zig-ultralight

Zig bindings for Ultralight.

## Usage

Requires Zig `0.12.0-dev.3180+83e578a18` ([nominated Zig](https://machengine.org/about/nominated-zig/) `2024.3.0-mach`) or later.

Add zig-ultralight to `build.zig.zon`:

```
.{
    .dependencies = .{
        .ultralight = .{
            .url = "https://github.com/nDimensional/zig-ultralight/archive/$COMMIT.tar.gz",
            // .hash = "12201d93aa50f0ebfb2e529a00c6c6f51f80ed86a0d857b4034f3037d1f240c7ddea",
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
