const std = @import("std");

const c = @import("../c.zig");
const utils = @import("./utils.zig");
const getString = utils.getString;

///
/// This is only needed if you are not calling ulCreateApp().
///
/// Initializes the platform font loader and sets it as the current FontLoader.
///
pub fn enablePlatformFontLoader() void {
    c.ulEnablePlatformFontLoader();
}

///
/// This is only needed if you are not calling ulCreateApp().
///
/// Initializes the platform file system (needed for loading file:/// URLs) and
/// sets it as the current FileSystem.
///
/// You can specify a base directory path to resolve relative paths against.
///
pub fn enablePlatformFileSystem(base_dir: []const u8) void {
    c.ulEnablePlatformFileSystem(c.ulCreateStringUTF8(base_dir.ptr, base_dir.len));
}

///
/// This is only needed if you are not calling ulCreateApp().
///
/// Initializes the default logger (writes the log to a file).
///
/// You should specify a writable log path to write the log to
/// for example "./ultralight.log".
///
pub fn enableDefaultLogger(base_dir: []const u8) void {
    c.ulEnableDefaultLogger(c.ulCreateStringUTF8(base_dir.ptr, base_dir.len));
}

///
/// Set a custom Logger implementation.
///
/// This is used to log debug messages to the console or to a log file.
///
/// You should call this before ulCreateRenderer() or ulCreateApp().
///
pub fn setLogger(impl: c.ULLogger) void {
    c.ulPlatformSetLogger(impl);
}

fn logMessage(log_level: c.ULLogLevel, message: c.ULString) callconv(.C) void {
    switch (log_level) {
        c.kLogLevel_Error => std.log.err("[ul] {s}", .{getString(message)}),
        c.kLogLevel_Warning => std.log.warn("[ul] {s}", .{getString(message)}),
        c.kLogLevel_Info => std.log.info("[ul] {s}", .{getString(message)}),
        else => @panic("invalid log level"),
    }
}

pub const logger = c.ULLogger{ .log_message = &logMessage };

///
/// Set a custom FileSystem implementation.
///
/// The library uses this to load all file URLs (eg, <file:///page.html>).
///
/// You can provide the library with your own FileSystem implementation so that file assets are
/// loaded from your own pipeline.
///
/// You should call this before ulCreateRenderer() or ulCreateApp().
///
pub fn setFileSystem(impl: c.ULFileSystem) void {
    c.ulPlatformSetFileSystem(impl);
}

fn fileExists(path: c.ULString) callconv(.C) bool {
    std.fs.cwd().access(getString(path), .{ .mode = .read_only }) catch |err| {
        switch (err) {
            error.FileNotFound => return false,
            else => {
                std.log.err("error accessing file: {any}", .{err});
                return false;
            },
        }
    };

    return true;
}

fn getFileMimeType(_: c.ULString) callconv(.C) c.ULString {
    return c.ulCreateString("application/unknown");
}

fn getFileCharset(_: c.ULString) callconv(.C) c.ULString {
    return c.ulCreateString("utf-8");
}

fn openFile(path: c.ULString) callconv(.C) c.ULBuffer {
    const fd = std.posix.open(getString(path), .{}, 644) catch |err| {
        std.log.err("error opening file: {any}", .{err});
        return null;
    };

    defer std.posix.close(fd);

    const stat = std.posix.fstat(fd) catch |err| {
        std.log.err("error opening file: {any}", .{err});
        return null;
    };

    const data = std.posix.mmap(null, @intCast(stat.size), std.posix.PROT.READ, .{ .TYPE = .SHARED }, fd, 0) catch |err| {
        std.log.err("error opening file: {any}", .{err});
        return null;
    };

    return c.ulCreateBuffer(data.ptr, @intCast(stat.size), @ptrFromInt(data.len), &destroyFileBuffer);
}

fn destroyFileBuffer(user_data: ?*anyopaque, data: ?*anyopaque) callconv(.C) void {
    const ptr: [*]align(std.mem.page_size) const u8 = @alignCast(@ptrCast(data));
    const len = @intFromPtr(user_data);
    std.os.munmap(ptr[0..len]);
}

pub const filesystem = c.ULFileSystem{
    .file_exists = &fileExists,
    .get_file_mime_type = &getFileMimeType,
    .get_file_charset = &getFileCharset,
    .open_file = &openFile,
};
