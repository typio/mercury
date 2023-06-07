const std = @import("std");
const net = std.net;

const cli = @import("zig_cli");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const ClientOptions = struct {
    host: cli.Option = .{
        .long_name = "host",
        .short_alias = 'h',
        .help = "host to connect to",
        .value = cli.OptionValue{ .string = "localhost" },
    },
    port: cli.Option = .{
        .long_name = "port",
        .short_alias = 'p',
        .help = "port to connect to",
        .value = cli.OptionValue{ .int = 3333 },
    },
};

var clientOptions = ClientOptions{};

var app = &cli.App{
    .name = "mercury client",
    .options = &.{ &clientOptions.host, &clientOptions.port },
    .action = startClient,
};

pub fn main() !void {
    return cli.run(app, allocator);
}

fn startClient(_: []const []const u8) !void {
    var h = clientOptions.host.value.string.?;
    if (std.mem.eql(u8, h, "localhost")) {
        h = "127.0.0.1";
    }

    var p = @intCast(u16, clientOptions.port.value.int.?);

    const address = try net.Address.resolveIp(h, p);

    const stream = net.tcpConnectToAddress(address) catch |err| {
        std.log.err("Unable to connect to server at {}: {}", .{ address, err });
        return;
    };
    std.log.debug("Client connected: {}", .{stream});

    while (true) {
        var message: []u8 = try readUntilDelimiter(stream, '\x1E');
        defer allocator.free(message);
        if (message.len > 0) {
            std.log.debug("Received from server: {s}", .{message});
        }
    }
}

fn readUntilDelimiter(stream: net.Stream, delimiter: u8) ![]u8 {
    var message = std.ArrayList(u8).init(allocator);

    while (true) {
        var byte: [1]u8 = [1]u8{0};
        _ = try stream.read(byte[0..]);
        if (byte[0] == delimiter) break;
        try message.append(byte[0]);
    }

    var messageSlice = message.toOwnedSlice();
    message.deinit();
    return messageSlice;
}
