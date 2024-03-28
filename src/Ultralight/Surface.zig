const c = @import("../c.zig");

const Surface = @This();

ptr: c.ULSurface,

///
/// Width (in pixels).
///
pub fn getWidth(self: Surface) u32 {
    return c.ulSurfaceGetWidth(self.ptr);
}

///
/// Height (in pixels).
///
pub fn getHeight(self: Surface) u32 {
    return c.ulSurfaceGetHeight(self.ptr);
}

///
/// Number of bytes between rows (usually width * 4)
///
pub fn getRowBytes(self: Surface) u32 {
    return c.ulSurfaceGetRowBytes(self.ptr);
}

///
/// Size in bytes.
///
pub fn getSize(self: Surface) usize {
    return c.ulSurfaceGetSize(self.ptr);
}

///
/// Lock the pixel buffer and get a pointer to the beginning of the data for reading/writing.
///
/// Native pixel format is premultiplied BGRA 32-bit (8 bits per channel).
///
pub fn lockPixels(self: Surface) []u8 {
    const ptr: [*]u8 = @ptrCast(c.ulSurfaceLockPixels(self.ptr));
    const len = self.getSize();
    return ptr[0..len];
}

///
/// Unlock the pixel buffer.
///
pub fn unlockPixels(self: Surface) void {
    c.ulSurfaceUnlockPixels(self.ptr);
}

///
/// Resize the pixel buffer to a certain width and height (both in pixels).
///
/// This should never be called while pixels are locked.
///
pub fn resize(self: Surface, width: u32, height: u32) void {
    c.ulSurfaceResize(self.ptr, width, height);
}

pub const IntRect = struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,

    pub fn isEmpty(rect: IntRect) bool {
        return c.ulIntRectIsEmpty(.{
            .left = rect.left,
            .top = rect.top,
            .right = rect.right,
            .bottom = rect.bottom,
        });
    }
};

///
/// Set the dirty bounds to a certain value.
///
/// This is called after the Renderer paints to an area of the pixel buffer. (The new value will be
/// joined with the existing dirty_bounds())
///
pub fn setDirtyBounds(self: Surface, bounds: IntRect) void {
    c.ulSurfaceSetDirtyBounds(self.ptr, .{
        .left = bounds.left,
        .top = bounds.top,
        .right = bounds.right,
        .bottom = bounds.bottom,
    });
}

///
/// Get the dirty bounds.
///
/// This value can be used to determine which portion of the pixel buffer has been updated since the
/// last call to ulSurfaceClearDirtyBounds().
///
/// The general algorithm to determine if a Surface needs display is:
/// <pre>
///   if (!ulIntRectIsEmpty(ulSurfaceGetDirtyBounds(surface))) {
///       // Surface pixels are dirty and needs display.
///       // Cast Surface to native Surface and use it here (pseudo code)
///       DisplaySurface(surface);
///
///       // Once you're done, clear the dirty bounds:
///       ulSurfaceClearDirtyBounds(surface);
///  }
///  </pre>
///
pub fn getDirtyBounds(self: Surface) IntRect {
    const bounds = c.ulSurfaceGetDirtyBounds(self.ptr);
    return .{
        .left = bounds.left,
        .top = bounds.top,
        .right = bounds.right,
        .bottom = bounds.bottom,
    };
}

///
/// Clear the dirty bounds.
///
/// You should call this after you're done displaying the Surface.
///
pub fn clearDirtyBounds(self: Surface) void {
    c.ulSurfaceClearDirtyBounds(self.ptr);
}

///
/// Get the underlying user data pointer (this is only valid if you have set a custom surface
/// implementation via ulPlatformSetSurfaceDefinition).
///
/// This will return nullptr if this surface is the default ULBitmapSurface.
///
pub fn getUserData(self: Surface) ?*anyopaque {
    return c.ulSurfaceGetUserData(self.ptr);
}
