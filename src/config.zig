const ini = @import("ini");
const std = @import("std");

// Add to this structure to automatically add to the config
pub const config = struct {
    network_port: u16,
};

pub const ConfigError = error{
    UnknownKey,
    MissingKey,
};

fn make_opt_struct(comptime in: type) type {
    if (@typeInfo(in) != .Struct) @compileError("Type must be a struct type.");
    var fields: [std.meta.fields(in).len]std.builtin.Type.StructField = undefined;
    for (std.meta.fields(in), 0..) |t, i| {
        const fieldType = @Type(.{ .Optional = .{ .child = t.type } });
        const fieldName: [:0]const u8 = t.name[0..];
        fields[i] = .{
            .name = fieldName,
            .type = fieldType,
            .default_value = &@as(fieldType, null),
            .is_comptime = false,
            .alignment = 0,
        };
    }
    return @Type(.{
        .Struct = .{
            .layout = .auto,
            .fields = fields[0..],
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        },
    });
}

const tmp_config = make_opt_struct(config);

const ini_field = struct {
    const Self = @This();

    full_name: []const u8,
    value: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(section: ?[]const u8, kv: ini.KeyValue, allocator: std.mem.Allocator) !ini_field {
        const actual_section = section orelse "default";
        const len_total = actual_section.len + kv.key.len + 1; // +1 to account for the underscore in the final name
        const fname = try allocator.alloc(u8, len_total);
        _ = try std.fmt.bufPrint(fname, "{s}_{s}", .{ actual_section, kv.key });
        const fvalue = try allocator.dupe(u8, kv.value);
        return .{
            .allocator = allocator,
            .full_name = fname,
            .value = fvalue,
        };
    }

    pub fn deinit(self: *const Self) void {
        self.allocator.free(self.full_name);
        self.allocator.free(self.value);
    }
};

fn map_opt_struct_to_struct(opt_stc: type, stc: type, from: *const opt_stc) stc {
    var to: stc = undefined;
    inline for (std.meta.fields(opt_stc)) |f| {
        if (@typeInfo(f.type) != .Optional)
            @compileError("Field " ++ f.name ++ " from " ++ @typeName(opt_stc) ++ " has type " ++ @typeName(f.type) ++ " that is not optional");
        const target_type = @typeInfo(f.type).Optional.child;
        const current_target_type = @TypeOf(@field(to, f.name));
        if (target_type != current_target_type)
            @compileError("Field " ++ f.name ++ " has mismatched types " ++ @typeName(target_type) ++ " != " ++ @typeName(current_target_type));
        if (@field(from, f.name) == null)
            @panic(f.name ++ " is missing from config");
        @field(to, f.name) = @field(from, f.name).?;
    }
    return to;
}

fn map_value(kv: ini_field, conf: *tmp_config) !void {
    inline for (std.meta.fields(@TypeOf(conf.*))) |f| {
        if (std.mem.eql(u8, f.name, kv.full_name)) {
            const target_type = @typeInfo(f.type).Optional.child;
            @field(conf, f.name) = switch (target_type) {
                u16, u32, u64, i16, i32, i64 => try std.fmt.parseInt(target_type, kv.value, 0),
                else => @panic("You probably need to implement another type :3"),
            };
            return;
        }
    }
    return ConfigError.UnknownKey;
}

pub fn parse(filepath: []const u8, allocator: std.mem.Allocator) !config {
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    var parser = ini.parse(allocator, file.reader(), ";#");
    defer parser.deinit();

    var current_section: ?[]const u8 = null;
    defer {
        if (current_section) |sec|
            allocator.free(sec);
    }
    var fields = std.ArrayList(ini_field).init(allocator);
    defer {
        for (fields.items) |f|
            f.deinit();
        fields.deinit();
    }
    var tmp: tmp_config = .{};
    while (try parser.next()) |record| {
        switch (record) {
            .section => |heading| {
                if (current_section) |sec|
                    allocator.free(sec);
                current_section = try allocator.dupe(u8, heading);
            },
            .property => |kv| try fields.append(try ini_field.init(current_section, kv, allocator)),
            .enumeration => |_| @panic("No support for enumerations"),
        }
    }
    for (fields.items) |f|
        try map_value(f, &tmp);
    return map_opt_struct_to_struct(tmp_config, config, &tmp);
}