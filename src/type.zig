const std = @import("std");
const ReturnType = @import("function.zig").ReturnType;
const testing = std.testing;
const Type = std.builtin.Type;

/// Returns new type that is not optional.
pub inline fn NonOptional(comptime T: type) type {
    comptime {
        const type_info = @typeInfo(T);

        switch (type_info) {
            inline .optional => |optional| return optional.child,
            else => @compileError("Can't remove optional type from " ++ @typeName(T) ++ " as it is not optional."),
        }
    }
}

test "NonOptional" {
    const S = struct {
        a: i32,
        b: ?u64,
        c: *const anyopaque,
    };

    try testing.expectEqual(NonOptional(?S), S);
}

/// Returns new type that has no error union.
pub inline fn NonError(comptime T: type) type {
    comptime {
        const type_info = @typeInfo(T);

        switch (type_info) {
            inline .error_union => |err| return err.payload,
            else => @compileError("Can't remove error type from " ++ @typeName(T) ++ " as it is does not have an error union."),
        }
    }
}

test "NonError" {
    const SomeError = error{ReallyBadError};

    const foo = (struct {
        pub fn foo() SomeError!bool {
            return true;
        }
    }).foo;

    const T = NonError(ReturnType(foo));

    try testing.expectEqual(T, bool);
}

/// Returns new type that is not a pointer.
pub inline fn NonPointer(comptime T: type) type {
    comptime {
        const type_info = @typeInfo(T);

        switch (type_info) {
            inline .pointer => |ptr| return ptr.child,
            else => @compileError("Can't remove pointer type from " ++ @typeName(T) ++ " as it is not a pointer type."),
        }
    }
}

test "NonPointer" {
    const T = *i32;

    try testing.expectEqual(NonPointer(T), i32);
}

pub inline fn Is(comptime v: anytype, comptime T: type) bool {
    comptime {
        return @TypeOf(v) == T;
    }
}

test "Is" {
    const a: *i32 = undefined;

    try testing.expect(Is(a, *i32));
}

/// Returns a new unsigned integer type which is the number of bits it takes to store the number of bits of T.
/// Examples:
/// LogBits(u256) -> u8
/// LogBits(i32) -> u5
pub inline fn LogBits(comptime T: type) type {
    comptime {
        return @Type(
            std.builtin.Type{
                .int = .{
                    .bits = std.math.log2(@typeInfo(T).int.bits),
                    .signedness = .unsigned,
                },
            },
        );
    }
}

test "LogBits" {
    try testing.expectEqual(u8, LogBits(u256));
    try testing.expectEqual(u8, LogBits(i256));
    try testing.expectEqual(u7, LogBits(u128));
    try testing.expectEqual(u7, LogBits(i128));
    try testing.expectEqual(u6, LogBits(u64));
    try testing.expectEqual(u6, LogBits(i64));
    try testing.expectEqual(u5, LogBits(u32));
    try testing.expectEqual(u5, LogBits(i32));
    try testing.expectEqual(u4, LogBits(u16));
    try testing.expectEqual(u4, LogBits(i16));
    try testing.expectEqual(u3, LogBits(u8));
    try testing.expectEqual(u3, LogBits(i8));
    try testing.expectEqual(u2, LogBits(u4));
    try testing.expectEqual(u2, LogBits(i4));
    try testing.expectEqual(u1, LogBits(u2));
    try testing.expectEqual(u1, LogBits(i2));
}
