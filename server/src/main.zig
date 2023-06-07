const std = @import("std");
const net = std.net;
const Thread = std.Thread;
const cli = @import("zig_cli");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const ServerOptions = struct {
    host: cli.Option = .{
        .long_name = "host",
        .short_alias = 'h',
        .help = "host to listen on",
        .value = cli.OptionValue{ .string = "localhost" },
    },
    port: cli.Option = .{
        .long_name = "port",
        .short_alias = 'p',
        .help = "port to bind to",
        .value = cli.OptionValue{ .int = 3333 },
    },
};

var serverOptions = ServerOptions{};

var app = &cli.App{
    .name = "mercury server",
    .options = &.{ &serverOptions.host, &serverOptions.port },
    .action = startServer,
};

pub fn main() !void {
    return cli.run(app, allocator);
}

// const ServerControl = struct {
//     shouldStop: bool = false,
//     mutex: Thread.Mutex = .{},
//     condition: Thread.Condition = .{},
// };

// var serverControl = ServerControl{};

// serverControl.mutex.lock();
// defer serverControl.mutex.unlock();
// if (serverControl.shouldStop) break;

fn startServer(_: []const []const u8) !void {
    var h = serverOptions.host.value.string.?;
    if (std.mem.eql(u8, h, "localhost")) {
        h = "127.0.0.1";
    }

    var p = @intCast(u16, serverOptions.port.value.int.?);

    const address = try net.Address.resolveIp(h, p);
    std.log.debug("Resolved address: {}", .{address});

    var serverStream = net.StreamServer.init(.{ .reuse_address = true });

    try serverStream.listen(address);
    std.log.debug("Server started listening: {}", .{serverStream});

    try handleServerConnection(&serverStream);
    // const serverThread = try Thread.spawn(.{}, handleServerConnection, .{&serverStream});
    //
    // defer {
    //     serverControl.mutex.lock();
    //     serverControl.shouldStop = true;
    //     serverControl.condition.signal();
    //     serverControl.mutex.unlock();
    //     serverThread.join();
    //     serverStream.deinit();
    // }
}

fn handleServerConnection(_serverStream: *net.StreamServer) !void {
    while (true) {
        var conn = _serverStream.accept() catch |err| {
            std.log.debug("Error accepting client connection: {}", .{err});
            return;
        };

        std.log.debug("Client connected.", .{});
        _ = try Thread.spawn(.{}, handleClientConnection, .{conn});
    }
}

fn handleClientConnection(conn: net.StreamServer.Connection) !void {
    defer conn.stream.close();

    _ = try conn.stream.write("Hello new client!\x1E");

    while (true) {
        var buf: [1024]u8 = undefined;
        const read_len = try conn.stream.readAll(&buf);
        if (read_len == 0) break;

        _ = try conn.stream.write(buf[0..read_len]);
    }
}
