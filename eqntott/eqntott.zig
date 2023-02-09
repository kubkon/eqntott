const std = @import("std");
const fs = std.fs;
const mem = std.mem;

const c = @cImport({
    @cInclude("x.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

export var infd: std.c.fd_t = -1;
export var exprs: [c.NOUTPUTS]*c.BNODE = undefined;

extern var ninputs: i32;
extern var noutputs: i32;
extern "c" fn yyparse() void;

const usage =
    \\Usage: eqntott <file>
    \\
    \\General options:
    \\-h, --help                    Print this help and exit
    \\
;

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const all_args = try std.process.argsAlloc(arena);
    const args = all_args[1..];

    const stderr = std.io.getStdOut().writer();

    var file_path: ?[]const u8 = null;
    var arg_index: usize = 0;
    while (arg_index < args.len) : (arg_index += 1) {
        const arg = args[arg_index];
        if (mem.eql(u8, "-h", arg) or mem.eql(u8, "--help", arg)) {
            return stderr.writeAll(usage);
        } else if (mem.startsWith(u8, "-", arg)) {
            return stderr.print("fatal: unknown flag {s}", .{arg});
        } else {
            file_path = arg;
        }
    }

    if (file_path == null) {
        return stderr.writeAll("fatal: no input file specified\n\n");
    }

    const file = try fs.cwd().openFile(file_path.?, .{});
    defer file.close();
    infd = file.handle;
    yyparse();

    var i: i32 = 0;
    while (i < noutputs) : (i += 1) {
        const expr = exprs[@intCast(usize, i)];
        std.log.warn("expr = {any}", .{expr.*});
    }
}
