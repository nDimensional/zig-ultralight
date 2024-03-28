const c = @import("../c.zig");

const Bitmap = @This();

ptr: c.ULBitmap,

///
/// Create empty bitmap.
///
pub fn createEmptyBitmap() Bitmap {
    const ptr = c.ulCreateEmptyBitmap();
    return .{ .ptr = ptr };
}

pub const Format = enum {
    A8_UNORM,
    BGRA8_UNORM_SRGB,
};

///
/// Create bitmap with certain dimensions and pixel format.
///
pub fn createBitmap(width: u32, height: u32, format: Format) Bitmap {
    const ptr = c.ulCreateBitmap(width, height, switch (format) {
        .A8_UNORM => c.kBitmapFormat_A8_UNORM,
        .BGRA8_UNORM_SRGB => c.kBitmapFormat_BGRA8_UNORM_SRGB,
    });

    return .{ .ptr = ptr };
}

///
/// Create bitmap from existing pixel buffer. @see Bitmap for help using this function.
///
pub fn createBitmapFromPixels(width: u32, height: u32, format: Format, row_bytes: u32, pixels: []const u8, should_copy: bool) Bitmap {
    const bitmap_format = switch (format) {
        .A8_UNORM => c.kBitmapFormat_A8_UNORM,
        .BGRA8_UNORM_SRGB => c.kBitmapFormat_BGRA8_UNORM_SRGB,
    };

    const ptr = c.ulCreateBitmapFromPixels(
        width,
        height,
        bitmap_format,
        row_bytes,
        pixels.ptr,
        pixels.len,
        should_copy,
    );

    return .{ .ptr = ptr };
}

///
/// Create bitmap from copy.
///
pub fn copy(self: Bitmap) Bitmap {
    const ptr = c.ulCreateBitmapFromCopy(self.ptr);
    return .{ .ptr = ptr };
}

///
/// Destroy a bitmap (you should only destroy Bitmaps you have explicitly created via one of the
/// creation functions above.
///
pub fn destroy(self: Bitmap) void {
    c.ulDestroyBitmap(self.ptr);
}

///
/// Get the width in pixels.
///
pub fn getWidth(self: Bitmap) u32 {
    return c.ulBitmapGetWidth(self.ptr);
}

///
/// Get the height in pixels.
///
pub fn getHeight(self: Bitmap) u32 {
    return c.ulBitmapGetHeight(self.ptr);
}

///
/// Get the pixel format.
///
pub fn getPixelFormat(self: Bitmap) Format {
    return switch (c.ulBitmapGetFormat(self.ptr)) {
        c.kBitmapFormat_A8_UNORM => Format.A8_UNORM,
        c.kBitmapFormat_BGRA8_UNORM_SRGB => Format.BGRA8_UNORM_SRGB,
    };
}

///
/// Get the bytes per pixel.
///
pub fn getBytesPerPixel(self: Bitmap) u32 {
    return c.ulBitmapGetBpp(self.ptr);
}

///
/// Get the number of bytes per row.
///
pub fn getRowBytes(self: Bitmap) u32 {
    return c.ulBitmapGetRowBytes(self.ptr);
}

///
/// Get the size in bytes of the underlying pixel buffer.
///
pub fn getSize(self: Bitmap) usize {
    return c.ulBitmapGetSize(self.ptr);
}

///
/// Whether or not this bitmap owns its own pixel buffer.
///
pub fn ownsPixels(self: Bitmap) bool {
    return c.ulBitmapOwnsPixels(self.ptr);
}

///
/// Lock pixels for reading/writing, returns pointer to pixel buffer.
///
pub fn lockPixels(self: Bitmap) []u8 {
    const ptr: [*]u8 = @ptrCast(c.ulBitmapLockPixels(self.ptr));
    const len = self.getSize();
    return ptr[0..len];
}

///
/// Unlock pixels after locking.
///
pub fn unlockPixels(self: Bitmap) void {
    c.ulBitmapUnlockPixels(self.ptr);
}

///
/// Whether or not this bitmap is empty.
///
pub fn isEmpty(self: Bitmap) void {
    return c.ulBitmapIsEmpty(self.ptr);
}

///
/// Reset bitmap pixels to 0.
///
pub fn erase(self: Bitmap) void {
    c.ulBitmapErase(self.ptr);
}

///
/// Write bitmap to a PNG on disk.
///
pub fn writePNG(self: Bitmap, path: [*:0]const u8) void {
    // TODO
    _ = c.ulBitmapWritePNG(self.ptr, path);
}

///
/// This converts a BGRA bitmap to RGBA bitmap and vice-versa by swapping the red and blue channels.
///
pub fn swapRedBlueChannels(self: Bitmap) void {
    c.ulBitmapSwapRedBlueChannels(self.ptr);
}
