const std = @import("std");

const ul = @import("ul");

const Platform = ul.Ultralight.Platform;
const Config = ul.Ultralight.Config;
const View = ul.Ultralight.View;

const App = ul.AppCore.App;
const Window = ul.AppCore.Window;
const Overlay = ul.AppCore.Overlay;
const Settings = ul.AppCore.Settings;

const Context = ul.JavaScriptCore.Context;
const ValueRef = ul.JavaScriptCore.ValueRef;
const ObjectRef = ul.JavaScriptCore.ObjectRef;

pub fn main() !void {
    var env: Environment = undefined;
    try env.init();
    defer env.deinit();

    env.run();
}

const Environment = struct {
    config: Config,
    settings: Settings,

    app: App,
    window: Window,
    overlay: Overlay,
    view: View,
    html: File,

    pub fn init(env: *Environment) !void {
        Platform.enablePlatformFileSystem(".");
        Platform.setLogger(Platform.logger);

        env.config = Config.create();
        env.config.setResourcePathPrefix("SDK/resources/");

        env.settings = Settings.create();

        env.app = App.create(env.settings, env.config);
        env.app.setUpdateCallback(Environment, env, &onUpdate);

        const monitor = env.app.getMainMonitor();
        env.window = Window.create(monitor, .{
            .width = 600,
            .height = 400,
            .tilted = true,
            .resizable = true,
        });

        env.overlay = Overlay.create(env.window, env.window.getWidth(), env.window.getHeight(), 0, 0);

        env.view = env.overlay.getView();

        env.view.setDOMReadyCallback(Environment, env, &onDOMReady);
        env.view.setConsoleMessageCallback(Environment, env, &onConsoleMessage);
        env.window.setResizeCallback(Environment, env, &onWindowResize);

        env.html = try File.init("example.html");
    }

    pub fn deinit(self: Environment) void {
        self.overlay.destroy();
        self.window.destroy();
        self.app.destroy();
        self.config.destroy();
        self.settings.destroy();

        self.html.deinit();
    }

    pub fn run(self: *Environment) void {
        self.view.loadHTML(self.html.data);
        self.app.run();
    }

    fn onDOMReady(env: *Environment, event: View.DOMReadyEvent) void {
        const ctx = event.view.lock();
        defer event.view.unlock();

        // create a class with some instance methods
        const class = ctx.createClass(Environment, "Environment", &.{
            .{ .name = "boop", .exec = &boop },
        });

        const global = ctx.getGlobal();
        ctx.setProperty(global, "env", class.make(env));
        ctx.evaluateScript("console.log('HELLO WORLD!!')") catch |err| {
            std.log.err("failed to evaluate script: {s}", .{@errorName(err)});
        };
    }

    fn boop(_: *Environment, ctx: Context, args: []const ValueRef) !ValueRef {
        const val = ctx.getNumber(args[0]);
        std.log.info("boop({d}) called from JavaScript context", .{val});

        return null;
    }

    fn onConsoleMessage(_: *Environment, event: View.ConsoleMessageEvent) void {
        const log = std.io.getStdOut().writer();
        const err = switch (event.level) {
            .Log => log.print("[console] [log] {s}\n", .{event.message}),
            .Warning => log.print("[console] [warn] {s}\n", .{event.message}),
            .Error => log.print("[console] [error] {s}\n", .{event.message}),
            .Debug => log.print("[console] [debug] {s}\n", .{event.message}),
            .Info => log.print("[console] [info] {s}\n", .{event.message}),
        };

        err catch @panic("fjkdls");
    }

    fn onWindowResize(env: *Environment, event: Window.ResizeEvent) void {
        env.overlay.resize(event.window.getWidth(), event.window.getHeight());
    }

    fn onUpdate(_: *Environment) void {}
};

const File = struct {
    data: []align(std.heap.page_size_min) const u8,

    pub fn init(path: []const u8) !File {
        const fd = try std.posix.open(path, .{}, 644);
        defer std.posix.close(fd);

        const stat = try std.posix.fstat(fd);
        const data = try std.posix.mmap(null, @intCast(stat.size), std.posix.PROT.READ, .{ .TYPE = .SHARED }, fd, 0);
        return File{ .data = data };
    }

    pub fn deinit(self: File) void {
        std.posix.munmap(self.data);
    }
};
