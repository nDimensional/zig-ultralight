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
        Platform.setFileSystem(Platform.filesystem);
        Platform.setLogger(Platform.logger);

        env.config = Config.init();
        env.config.setResourcePathPrefix("SDK/resources/");

        env.settings = Settings.init();

        env.app = App.init(env.settings, env.config);
        env.app.setUpdateCallback(Environment, env, &onUpdate);

        const monitor = env.app.getMainMonitor();
        env.window = Window.init(monitor, .{
            .width = 1200,
            .height = 800,
            .tilted = true,
            .resizable = true,
        });

        env.overlay = Overlay.init(env.window, env.window.getWidth(), env.window.getHeight(), 0, 0);

        env.view = env.overlay.getView();

        env.view.setDOMReadyCallback(Environment, env, &onDOMReady);
        env.view.setConsoleMessageCallback(Environment, env, &onConsoleMessage);
        env.window.setResizeCallback(Environment, env, &onWindowResize);

        env.html = try File.init("example.html");
    }

    pub fn deinit(self: Environment) void {
        self.overlay.deinit();
        self.window.deinit();
        self.app.deinit();
        self.config.deinit();
        self.settings.deinit();

        self.html.deinit();
    }

    pub fn run(self: *Environment) void {
        self.view.loadHTML(self.html.data);
        self.app.run();
    }

    fn onDOMReady(env: *Environment, event: View.DOMReadyEvent) void {
        const ctx = event.view.lock();
        defer event.view.unlock();

        const class = ctx.createClass(Environment, "Environment", &.{.{ .name = "boop", .exec = &boop }});
        const global = ctx.getGlobal();
        ctx.setProperty(global, "env", class.make(env));

        ctx.evaluateScript("window.env.boop()") catch @panic("window.env.boop failed");
    }

    fn boop(env: *Environment, ctx: Context, args: []const ValueRef) !ValueRef {
        _ = env; // autofix
        _ = ctx; // autofix
        _ = args; // autofix
        return null;
    }

    fn onConsoleMessage(_: *Environment, event: View.ConsoleMessageEvent) void {
        const log = std.io.getStdOut().writer();
        const err = switch (event.level) {
            .Log => log.print("[console.log] {s}\n", .{event.message}),
            .Warning => log.print("[console.warn] {s}\n", .{event.message}),
            .Error => log.print("[console.error] {s}\n", .{event.message}),
            .Debug => log.print("[console.debug] {s}\n", .{event.message}),
            .Info => log.print("[console.info] {s}\n", .{event.message}),
        };

        err catch @panic("fjkdls");
    }

    fn onWindowResize(env: *Environment, event: Window.ResizeEvent) void {
        env.overlay.resize(event.window.getWidth(), event.window.getHeight());
    }

    fn onUpdate(env: *Environment) void {
        _ = env; // autofix
    }
};

const File = struct {
    data: []align(std.mem.page_size) const u8,

    pub fn init(path: []const u8) !File {
        std.log.info("opening {s}", .{path});
        const fd = try std.os.open(path, std.os.O.RDONLY, 644);
        defer std.os.close(fd);

        const stat = try std.os.fstat(fd);
        const data = try std.os.mmap(null, @intCast(stat.size), std.os.PROT.READ, std.os.MAP.SHARED, fd, 0);
        return File{ .data = data };
    }

    pub fn deinit(self: File) void {
        std.os.munmap(self.data);
    }
};
