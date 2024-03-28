const std = @import("std");

const c = @import("../c.zig");
const utils = @import("./utils.zig");
const getString = utils.getString;

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

pub fn FileSystem(Impl: anytype) type {
    return struct {
        impl: *const Impl,
        fileExists: *const fn (impl: *const Impl, path: []const u8) bool,
        getFileMimeType: *const fn (impl: *const Impl, path: []const u8) []const u8,
        getFileCharset: *const fn (impl: *const Impl, path: []const u8) []const u8,
        openFile: *const fn (impl: *const Impl, path: []const u8) []u8,
        destroyFileBuffer: *const fn (impl: *const Impl, data: []u8) []u8,
    };
}

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

var path_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;

fn fileExists(path: c.ULString) callconv(.C) bool {
    std.log.info("fileExists: {s}", .{getString(path)});
    std.log.info("cwd: {s}", .{try std.fs.cwd().realpath(".", &path_buffer)});
    std.log.info("abs: {s}", .{try std.fs.cwd().realpath(getString(path), &path_buffer)});
    std.fs.cwd().access(getString(path), .{ .mode = .read_only }) catch |err| {
        switch (err) {
            error.FileNotFound => {
                std.log.info("fileExists: NO (FileNotFound)", .{});
                return false;
            },
            else => {
                std.log.err("error accessing filesystem: {any}", .{err});
                std.log.info("fileExists: NO ({any})", .{err});
                return false;
            },
        }
    };

    std.log.info("fileExists: YES", .{});
    return true;
}

fn getFileMimeType(_: c.ULString) callconv(.C) c.ULString {
    return c.ulCreateString("application/unknown");
}

fn getFileCharset(_: c.ULString) callconv(.C) c.ULString {
    return c.ulCreateString("utf-8");
}

fn openFile(path: c.ULString) callconv(.C) c.ULBuffer {
    const fd = std.os.open(getString(path), .{}, 644) catch |err| {
        std.log.err("error opening file: {any}", .{err});
        return null;
    };

    defer std.os.close(fd);

    const stat = std.os.fstat(fd) catch |err| {
        std.log.err("error opening file: {any}", .{err});
        return null;
    };

    const data = std.os.mmap(null, @intCast(stat.size), std.os.PROT.READ, .{ .TYPE = .SHARED }, fd, 0) catch |err| {
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
