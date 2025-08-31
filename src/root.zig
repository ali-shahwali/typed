pub const Params = @import("function.zig").Params;
pub const ParamType = @import("function.zig").ParamType;
pub const ReturnType = @import("function.zig").ReturnType;

pub const Omit = @import("struct.zig").Omit;
pub const Partial = @import("struct.zig").Partial;
pub const Pick = @import("struct.zig").Pick;
pub const Record = @import("struct.zig").Record;

pub const Is = @import("type.zig").Is;
pub const LogBits = @import("type.zig").LogBits;
pub const NonError = @import("type.zig").NonError;
pub const NonOptional = @import("type.zig").NonOptional;
pub const NonPointer = @import("type.zig").NonPointer;

test {
    _ = @import("function.zig");
    _ = @import("struct.zig");
    _ = @import("type.zig");
}
