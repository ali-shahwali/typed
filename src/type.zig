const std = @import("std");
const ReturnType = @import("function.zig").ReturnType;
const testing = std.testing;
const Type = std.builtin.Type;

/// Returns new type that is not optional.
pub inline fn NonOptional(comptime T: type) type {
    comptime {
        const type_info = @typeInfo(T);

        switch (type_info) {
            inline .Optional => |optional| return optional.child,
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
            inline .ErrorUnion => |err| return err.payload,
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
            inline .Pointer => |ptr| return ptr.child,
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
