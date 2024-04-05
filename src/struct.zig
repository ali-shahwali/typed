const std = @import("std");
const meta = std.meta;
const testing = std.testing;
const Type = std.builtin.Type;

inline fn assertIsStructType(comptime ty: Type) void {
    comptime {
        if (ty != .Struct) {
            @compileError("Can not use struct type util on non-struct type " ++ @typeName(@Type(ty)));
        }
    }
}

inline fn getField(comptime T: type, comptime field: meta.FieldEnum(T)) Type.StructField {
    comptime {
        const type_info = @typeInfo(T);
        switch (type_info) {
            inline .Struct => |s| {
                for (s.fields) |f| {
                    if (std.mem.eql(u8, f.name, @tagName(field))) return f;
                }
            },
            else => unreachable,
        }
    }
}

/// Returns a new type where every field is optional.
pub inline fn Partial(comptime T: type) type {
    comptime {
        const type_info = @typeInfo(T);

        assertIsStructType(type_info);

        switch (type_info) {
            inline .Struct => |s| {
                var optional_fields: []const Type.StructField = &[_]Type.StructField{};
                for (s.fields) |field| {
                    const OptionalType = switch (@typeInfo(field.type)) {
                        .Optional => field.type,
                        else => ?field.type,
                    };
                    const default_value: OptionalType = null;
                    const optional_field = [1]Type.StructField{.{
                        .alignment = field.alignment,
                        .name = field.name,
                        .type = OptionalType,
                        .is_comptime = false,
                        .default_value = @alignCast(@ptrCast(&default_value)),
                    }};

                    optional_fields = optional_fields ++ optional_field;
                }

                return @Type(Type{ .Struct = .{
                    .backing_integer = s.backing_integer,
                    .decls = &[_]Type.Declaration{},
                    .fields = optional_fields,
                    .is_tuple = s.is_tuple,
                    .layout = s.layout,
                } });
            },
            else => unreachable,
        }
    }
}

test "Partial" {
    const S = struct {
        a: i32,
        b: ?u64,
        c: *const anyopaque,
    };

    const type_info = @typeInfo(Partial(S));

    switch (type_info) {
        .Struct => |s| {
            comptime {
                for (s.fields) |field| {
                    const field_type_info = @typeInfo(field.type);

                    try testing.expect(field_type_info == .Optional);
                }
            }
        },
        else => unreachable,
    }
}

/// Return a new type with only fields specificed in `fields` picked out.
pub inline fn Pick(comptime T: type, comptime fields: []const meta.FieldEnum(T)) type {
    comptime {
        const type_info = @typeInfo(T);

        assertIsStructType(type_info);

        switch (type_info) {
            inline .Struct => |s| {
                var picked_fields: []const Type.StructField = &[_]Type.StructField{};

                for (fields) |field| {
                    const picked_field = [1]Type.StructField{getField(T, field)};
                    picked_fields = picked_fields ++ picked_field;
                }

                return @Type(Type{ .Struct = .{
                    .backing_integer = s.backing_integer,
                    .decls = &[_]Type.Declaration{},
                    .fields = picked_fields,
                    .is_tuple = s.is_tuple,
                    .layout = s.layout,
                } });
            },
            else => unreachable,
        }
    }
}

test "Pick" {
    const S = struct {
        a: i32,
        b: ?u64,
        c: *const anyopaque,
    };

    const T = Pick(S, &.{ .a, .c });

    const field_names = meta.fieldNames(T);

    try testing.expectEqualSlices([]u8, @ptrCast(field_names), @ptrCast(&[_][]const u8{ "a", "c" }));
}

/// Return a new type with fields specified in `fields` have been omitted.
pub inline fn Omit(comptime T: type, comptime fields: []const meta.FieldEnum(T)) type {
    comptime {
        const type_info = @typeInfo(T);

        assertIsStructType(type_info);

        switch (type_info) {
            inline .Struct => |s| {
                var remaining_fields: []const Type.StructField = &[_]Type.StructField{};

                for (s.fields) |field| {
                    var skip_field = false;
                    for (fields) |f| {
                        if (std.mem.eql(u8, field.name, @tagName(f))) {
                            skip_field = true;
                            break;
                        }
                    }

                    if (skip_field) continue;

                    const f = [1]Type.StructField{field};
                    remaining_fields = remaining_fields ++ f;
                }

                return @Type(Type{ .Struct = .{
                    .backing_integer = s.backing_integer,
                    .decls = &[_]Type.Declaration{},
                    .fields = remaining_fields,
                    .is_tuple = s.is_tuple,
                    .layout = s.layout,
                } });
            },
            else => unreachable,
        }
    }
}

test "Omit" {
    const S = struct {
        a: i32,
        b: ?u64,
        c: *const anyopaque,
    };

    const T = Omit(S, &.{.b});

    const field_names = meta.fieldNames(T);

    try testing.expectEqualSlices([]u8, @ptrCast(field_names), @ptrCast(&[_][]const u8{ "a", "c" }));
}
