const std = @import("std");
const fs = std.fs;
const mem = std.mem;

const c = @cImport({
    @cInclude("x.h");
    @cInclude("hdr.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

export var infd: std.c.fd_t = -1;
export var exprs: [c.NOUTPUTS]*c.BNODE = undefined;
export var pts: [c.NPTERMS]*c.PTERM = undefined;

extern var ninputs: i32;
extern var noutputs: i32;
extern var inorder: [*]*c.Nt;
extern var outorder: [*]*c.Nt;
extern var yyfile: *std.c.FILE;

extern "c" fn yyparse() void;
extern "c" fn canon(*c.BNODE) *c.BNODE;
extern "c" fn read_ones(*c.BNODE, i32) *c.PTERM;
extern "c" fn putpla([*]*c.PTERM, i32) void;
extern "c" fn cmppt(?*const anyopaque, ?*const anyopaque) i32;

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

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdOut().writer();

    var file_path: ?[:0]const u8 = null;
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

    yyfile = std.c.fopen(file_path.?, "r") orelse {
        return stderr.print("fatal: could not open file {s}\n\n", .{file_path.?});
    };
    defer _ = std.c.fclose(yyfile);
    yyparse();

    var ptexprs: [c.NOUTPUTS]*c.PTERM = undefined;

    var o: i32 = 0;
    while (o < noutputs) : (o += 1) {
        const expr = &exprs[@intCast(usize, o)];
        expr.* = canon(expr.*);
        ptexprs[@intCast(usize, o)] = read_ones(expr.*, o);
    }

    // Previous and following loops cannot be merged as `pts` is overwritten by both.
    var npts: i32 = 0;
    o = 0;
    while (o < noutputs) : (o += 1) {
        var pt = ptexprs[@intCast(usize, o)];
        while (true) {
            pt.index = @intCast(i16, c.ptindex(pt.ptand, ninputs));
            if (npts < c.NPTERMS) {
                pts[@intCast(usize, npts)] = pt;
                npts += 1;
            }
            if (pt.next) |next| {
                pt = next;
            } else break;
        }
    }

    try stdout.print(".i {d}\n", .{ninputs});
    try stdout.print(".o {d}\n", .{noutputs});
    try stdout.print(".p {d}\n", .{npts});
    try writeTruthTable(&pts, npts, stdout);
    try stdout.writeAll(".e\n");
}

fn writeTruthTable(pterms: [*]*c.PTERM, npts: i32, writer: anytype) !void {
    c.qsort(@intToPtr(?*anyopaque, @ptrToInt(pterms)), @intCast(usize, npts), @sizeOf(*c.PTERM), cmppt);
    var i: usize = 0;
    while (i < npts) : (i += 1) {
        try writeRow(pterms[i], writer);
    }
}

fn writeRow(pterm: *c.PTERM, writer: anytype) !void {
    const inc: [3]u8 = .{ '0', '1', '-' };
    const outc: [3]u8 = .{ '0', '1', 'x' };

    var i: usize = 0;
    while (i < ninputs) : (i += 1) {
        var buffer: [2]u8 = .{ inc[@intCast(usize, pterm.ptand[i])], 0 };
        try writer.print("{s}", .{&buffer});
    }

    try writer.writeAll(" ");

    i = 0;
    while (i < noutputs) : (i += 1) {
        var buffer: [2]u8 = .{ outc[@intCast(usize, pterm.ptor[i])], 0 };
        try writer.print("{s}", .{&buffer});
    }

    try writer.writeByte('\n');
}
