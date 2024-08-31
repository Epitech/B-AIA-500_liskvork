const std = @import("std");
const config = @import("config");

const semver = std.SemanticVersion.parse(config.version) catch unreachable;

pub fn main() !void {
    std.debug.print("version: {s}\n", .{config.version});
}
