const std = @import("std");

const panicky = @import("./panic_handler.zig");
const MainPanicHandler = panicky.NewPanicHandler(std.builtin.default_panic);

pub const io_mode = .blocking;

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, addr: ?usize) noreturn {
    MainPanicHandler.handle_panic(msg, error_return_trace, addr);
}

const CrashReporter = @import("./crash_reporter.zig");

pub extern "C" var _environ: ?*anyopaque;
pub extern "C" var environ: ?*anyopaque;

pub fn main() void {
    const bun = @import("root").bun;
    const Output = bun.Output;
    const Environment = bun.Environment;

    if (comptime Environment.isRelease and Environment.isPosix)
        CrashReporter.start() catch unreachable;
    if (comptime Environment.isWindows) {
        environ = @ptrCast(std.os.environ.ptr);
        _environ = @ptrCast(std.os.environ.ptr);
        bun.win32.STDOUT_FD = bun.toFD(std.io.getStdOut().handle);
        bun.win32.STDERR_FD = bun.toFD(std.io.getStdErr().handle);
        bun.win32.STDIN_FD = bun.toFD(std.io.getStdin().handle);
    }

    bun.start_time = std.time.nanoTimestamp();

    // The memory allocator makes a massive difference.
    // std.heap.raw_c_allocator and default_allocator perform similarly.
    // std.heap.GeneralPurposeAllocator makes this about 3x _slower_ than esbuild.
    // var root_alloc = @import("root").bun.ArenaAllocator.init(std.heap.raw_c_allocator);
    // var root_alloc_ = &root_alloc.allocator;

    var stdout = std.io.getStdOut();
    // var stdout = std.io.bufferedWriter(stdout_file.writer());
    var stderr = std.io.getStdErr();
    var output_source = Output.Source.init(stdout, stderr);

    Output.Source.set(&output_source);
    defer Output.flush();

    bun.CLI.Cli.start(bun.default_allocator, stdout, stderr, MainPanicHandler);
}

test "panic" {
    panic("woah", null);
}

pub const build_options = @import("build_options");

comptime {}
