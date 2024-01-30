const c = @import("../c.zig");

const Monitor = @import("Monitor.zig");

const Window = @This();

pub const CreateOptions = struct {
    width: u32 = 600,
    height: u32 = 400,
    fullscreen: bool = false,
    borderless: bool = false,
    tilted: bool = false,
    resizable: bool = false,
    maximizable: bool = false,
    hidden: bool = false,
};

ptr: c.ULWindow,

///
/// Create a new Window.
///
pub fn create(monitor: Monitor, options: CreateOptions) Window {
    var flags: c_uint = 0;
    if (options.borderless) flags |= c.kWindowFlags_Borderless;
    if (options.tilted) flags |= c.kWindowFlags_Titled;
    if (options.resizable) flags |= c.kWindowFlags_Resizable;
    if (options.maximizable) flags |= c.kWindowFlags_Maximizable;
    if (options.hidden) flags |= c.kWindowFlags_Hidden;

    const ptr = c.ulCreateWindow(monitor.ptr, options.width, options.height, options.fullscreen, flags);
    return .{ .ptr = ptr };
}

pub const CloseEvent = struct { window: Window };

pub fn setCloseCallback(
    self: Window,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: CloseEvent) void,
) void {
    const Callback = struct {
        fn exec(user_data_ptr: ?*anyopaque, windpw_ptr: c.ULWindow) callconv(.C) void {
            callback(@alignCast(@ptrCast(user_data_ptr)), .{ .window = .{ .ptr = windpw_ptr } });
        }
    };

    c.ulWindowSetCloseCallback(self.ptr, &Callback.exec, user_data);
}

pub const ResizeEvent = struct { window: Window, width: u32, height: u32 };

pub fn setResizeCallback(
    self: Window,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: ResizeEvent) void,
) void {
    const Callback = struct {
        fn exec(user_data_ptr: ?*anyopaque, windpw_ptr: c.ULWindow, width: u32, height: u32) callconv(.C) void {
            callback(@alignCast(@ptrCast(user_data_ptr)), .{
                .window = .{ .ptr = windpw_ptr },
                .width = width,
                .height = height,
            });
        }
    };

    c.ulWindowSetResizeCallback(self.ptr, &Callback.exec, user_data);
}

///
/// Destroy a Window.
///
pub fn destroy(self: Window) void {
    c.ulDestroyWindow(self.ptr);
}

///
/// Get window width (in screen coordinates).
///
pub fn getScreenWidth(self: Window) u32 {
    return c.ulWindowGetScreenWidth(self.ptr);
}

///
/// Get window width (in pixels).
///
pub fn getWidth(self: Window) u32 {
    return c.ulWindowGetWidth(self.ptr);
}

///
/// Get window height (in screen coordinates).
///
pub fn getScreenHeight(self: Window) u32 {
    return c.ulWindowGetScreenHeight(self.ptr);
}

///
/// Get window height (in pixels).
///
pub fn getHeight(self: Window) u32 {
    return c.ulWindowGetHeight(self.ptr);
}

///
/// Move the window to a new position (in screen coordinates) relative to the top-left of the
/// monitor area.
///
pub fn moveTo(self: Window, x: i32, y: i32) void {
    c.ulWindowMoveTo(self.ptr, x, y);
}

///
/// Move the window to the center of the monitor.
///
pub fn moveToCenter(self: Window) void {
    c.ulWindowMoveToCenter(self.ptr);
}

///
/// Get the x-position of the window (in screen coordinates) relative to the top-left of the
/// monitor area.
///
pub fn getPositionX(self: Window) i32 {
    return c.ulWindowGetPositionX(self.ptr);
}

///
/// Get the y-position of the window (in screen coordinates) relative to the top-left of the
/// monitor area.
///
pub fn getPositionY(self: Window) i32 {
    return c.ulWindowGetPositionY(self.ptr);
}

///
/// Get whether or not a window is fullscreen.
///
pub fn isFullscreen(self: Window) bool {
    return c.ulWindowIsFullscreen(self.ptr);
}

///
/// Get the DPI scale of a window.
///
pub fn getScale(self: Window) f64 {
    return c.ulWindowGetScale(self.ptr);
}

///
/// Set the window title.
///
pub fn setTitle(self: Window, title: [*:0]const u8) void {
    c.ulWindowSetTitle(self.ptr, title);
}

///
/// Set the cursor for a window.
///
pub fn setCursor(self: Window, cursor: c.ULCursor) void {
    c.ulWindowSetCursor(self.ptr, cursor);
}

///
/// Show the window (if it was previously hidden).
///
pub fn show(self: Window) void {
    c.ulWindowShow(self.ptr);
}

///
/// Hide the window.
///
pub fn hide(self: Window) void {
    c.ulWindowHide(self.ptr);
}

///
/// Whether or not the window is currently visible (not hidden).
///
pub fn isVisible(self: Window) bool {
    return c.ulWindowIsVisible(self.ptr);
}

///
/// Close a window.
///
pub fn close(self: Window) void {
    c.ulWindowClose(self.ptr);
}

///
/// Convert screen coordinates to pixels using the current DPI scale.
///
pub fn screenToPixels(self: Window, val: i32) i32 {
    return c.ulWindowScreenToPixels(self.ptr, val);
}

///
/// Convert pixels to screen coordinates using the current DPI scale.
///
pub fn pixelsToScreen(self: Window, val: i32) i32 {
    return c.ulWindowPixelsToScreen(self.ptr, val);
}

///
/// Get the underlying native window handle.
///
/// @note This is:  - HWND on Windows
///                 - NSWindow* on macOS
///                 - GLFWwindow* on Linux
///
pub fn getNativeHandle(self: Window) ?*anyopaque {
    return c.ulWindowGetNativeHandle(self.ptr);
}
