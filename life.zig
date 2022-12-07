const std = @import("std");

extern fn debug(message: [*]u8, length: usize) void;
extern fn render(image_data_ptr: [*]u8, image_data_len: usize, image_width: usize, image_height: usize) void;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
var rnd = std.rand.DefaultPrng.init(0);

const acorn =
    \\  #
    \\    #
    \\ ##  ###
    ;

var grid_cols: usize = 0;
var grid_rows: usize = 0;
var cells: []bool = &.{};
var prev_cells: []bool = &.{};
var cell_ages: []usize = &.{};
var image_data: []u8 = &.{};
var paused = false;

var brush: struct {
    x: usize,
    y: usize,
    painting: bool,
    color: bool,
} = .{
    .x = 0,
    .y = 0,
    .painting = false,
    .color = false,
};

fn print(comptime fmt: []const u8, args: anytype) void {
    var string = std.fmt.allocPrint(allocator, fmt, args) catch unreachable;
    defer allocator.free(string);
    debug(string.ptr, string.len);
}

fn reset() void {
    for (cells) |*on| on.* = false;
}

fn set(x: usize, y: usize, cell: bool) void {
    if (x >= 0 and y >= 0 and x < grid_cols and y < grid_rows) {
        cells[x + y * grid_cols] = cell;
    }
}

fn insertFromString(x: usize, y: usize, str: []const u8) void {
    var lines = std.mem.tokenize(u8, str, "\n");
    var j: usize = 0;
    while (lines.next()) |line| {
        for (line) |ch, i| {
            set(x + i, y + j, ch == '#');
        }
        j += 1;
    }
}

fn countLivingNeighbours(x: usize, y: usize) usize {
    return getNeighbour(x - 1, y - 1) +
        getNeighbour(x - 0, y - 1) +
        getNeighbour(x + 1, y - 1) +
        getNeighbour(x - 1, y - 0) +
        getNeighbour(x + 1, y - 0) +
        getNeighbour(x - 1, y + 1) +
        getNeighbour(x - 0, y + 1) +
        getNeighbour(x + 1, y + 1);
}

fn getNeighbour(x: usize, y: usize) usize {
    if (x >= 0 and y >= 0 and x < grid_cols and y < grid_rows) {
        return if (cells[x + y * grid_cols]) 1 else 0;
    } else {
        return 0;
    }
}

export fn update() void {
    if (!paused) {
        var next_cells = prev_cells;

        for (cells) |cell, i| {
            const x = @mod(i, grid_cols);
            const y = i / grid_cols;
            const n = countLivingNeighbours(x, y);
            const new = if (cell) n == 2 or n == 3 else n == 3;
            cell_ages[i] = if (cell == new) cell_ages[i] + 1 else 0;
            next_cells[i] = new;
        }

        prev_cells = cells;
        cells = next_cells;
    }

    for (cells) |on, i| {
        const j = i * 4;
        const fresh = cell_ages[i] <= 5;
        image_data[j + 0] = if (fresh) 0xF7 else 0xC6;
        image_data[j + 1] = if (fresh) 0xA4 else 0x47;
        image_data[j + 2] = if (fresh) 0x1E else 0x28;
        image_data[j + 3] = if (on) 0xFF else 0;
    }

    render(image_data.ptr, image_data.len, grid_cols, grid_rows);
}

export fn init(cols: usize, rows: usize) void {
    grid_cols = cols;
    grid_rows = rows;
    cells = allocator.alloc(bool, cols * rows) catch unreachable;
    prev_cells = allocator.alloc(bool, cols * rows) catch unreachable;
    image_data = allocator.alloc(u8, cols * rows * 4) catch unreachable;
    cell_ages = allocator.alloc(usize, cols * rows) catch unreachable;
    for (cells) |*on| on.* = false;
    for (cell_ages) |*v| v.* = 0;
    insertFromString(cols / 2, rows / 2, acorn);
}

export fn onKeyDown(key: u8) void {
    switch (key) {
        // Space to pause
        32 => paused = !paused,
        // Escape to reset
        27 => reset(),
        else => {}
    }
}

export fn onPointerDown() void {
    brush.painting = true;
    brush.color = !cells[brush.x + brush.y * grid_cols];
}

export fn onPointerUp() void {
    brush.painting = false;
}

export fn onPointerMove(x: usize, y: usize) void {
    brush.x = x;
    brush.y = y;
    if (brush.painting) set(brush.x, brush.y, brush.color);
}
