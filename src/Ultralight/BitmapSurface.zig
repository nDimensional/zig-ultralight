const c = @import("../c.zig");

const Bitmap = @import("./Bitmap.zig");

const BitmapSurface = @This();

ptr: c.ULBitmapSurface,

pub fn getBitmap(self: BitmapSurface) Bitmap {
    const ptr = c.ulBitmapSurfaceGetBitmap(self.ptr);
    return .{ .ptr = ptr };
}
