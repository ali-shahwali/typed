const std = @import("std");
const testing = std.testing;
const Type = std.builtin.Type;

inline fn assertIsFunctionType(comptime ty: Type) void {
    comptime {
        if (ty != .@"fn") {
            @compileError("Used function type util on non-function type " ++ @typeName(@Type(ty)));
        }
    }
}

/// Returns return type of `func`.
pub inline fn ReturnType(comptime func: anytype) type {
    comptime {
        const type_info = @typeInfo(@TypeOf(func));

        assertIsFunctionType(type_info);

        return type_info.@"fn".return_type orelse {
            @compileError("Function has no return type. This should not be possible but is possible due to the current Zig spec.");
        };
    }
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

test "ReturnType_with_ErrorUnion_and_Optional" {
    const SomeError = error{ReallyBadError};

    const foo = (struct {
        pub fn foo() SomeError!?bool {
            return true;
        }
    }).foo;

    try testing.expectEqual(ReturnType(foo), SomeError!?bool);
}

/// Returns the type of the parameter of `func` at index `param_idx`.
pub inline fn ParamType(comptime func: anytype, comptime param_idx: usize) type {
    comptime {
        const type_info = @typeInfo(@TypeOf(func));

        assertIsFunctionType(type_info);

        if (type_info.@"fn".params.len < param_idx) {
            @compileError("'param_idx' out of bounds.");
        } else {
            return type_info.@"fn".params[param_idx].type orelse {
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

/// Returns the types of the parameters of `func`.
pub inline fn Params(comptime func: anytype) []const Type {
    comptime {
        const type_info = @typeInfo(@TypeOf(func));

        assertIsFunctionType(type_info);

        var params: []const Type = &[_]Type{};
        for (type_info.@"fn".params) |param| {
            params = params ++ [_]Type{@typeInfo(param.type.?)};
        }

        return params;
    }
}

test "Params" {
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

    const params = Params(foo);

    try testing.expectEqual(params.len, 4);
}
