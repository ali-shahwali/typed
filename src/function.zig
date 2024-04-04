const std = @import("std");
const testing = std.testing;
const Type = std.builtin.Type;

inline fn withoutError(comptime ty: Type) Type {
    comptime {
        if (ty == .ErrorUnion) {
            return @typeInfo(ty.ErrorUnion.payload);
        } else {
            return ty;
        }
    }
}

inline fn assertIsFunctionType(comptime ty: Type) void {
    comptime {
        const unwrapped = withoutError(ty);
        if (unwrapped != .Fn) {
            @compileError("Used function type util on non-function type " ++ @typeName(@Type(ty)));
        }
    }
}

/// Returns return type of `func`.
/// If it has no return type, assumes its the same as the first param type.
pub inline fn ReturnType(comptime func: anytype) type {
    comptime {
        const type_info: Type = @typeInfo(@TypeOf(func));

        assertIsFunctionType(type_info);

        return type_info.Fn.return_type orelse {
            @compileError("Function has no return type. This should not be possible but is possible due to the current Zig spec.");
        };
    }
}

/// Returns the type of the parameter of `func` at index `param_idx`.
pub inline fn ParamType(comptime func: anytype, comptime param_idx: usize) type {
    comptime {
        const type_info: Type = @typeInfo(@TypeOf(func));

        assertIsFunctionType(type_info);

        if (type_info.Fn.params.len < param_idx) {
            @compileError("'param_idx' out of bounds.");
        } else {
            return type_info.Fn.params[param_idx].type orelse {
                @compileError("Function without params has no param type.");
            };
        }
    }
}

test "ParamType" {
    const S = struct {
        a: i32,
        b: u8,
    };

    const foo = (struct {
        fn foo(a: i32, b: u32, c: void, d: S) void {
            _ = a;
            _ = b;
            _ = c;
            _ = d;
        }
    }).foo;

    try testing.expectEqual(ParamType(foo, 0), i32);
    try testing.expectEqual(ParamType(foo, 1), u32);
    try testing.expectEqual(ParamType(foo, 2), void);
    try testing.expectEqual(ParamType(foo, 3), S);
}

test "ReturnType" {
    const S = struct {
        a: ?i32 = null,
        b: ?u8 = null,
    };

    const foo = (struct {
        fn foo() S {
            return S{};
        }
    }).foo;

    const bar = (struct {
        fn bar() ?S {
            return null;
        }
    }).bar;

    try testing.expectEqual(ReturnType(foo), S);
    try testing.expectEqual(ReturnType(bar), ?S);
}
