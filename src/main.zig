const std = @import("std");
const Game = @import("game.zig").Game;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var game: Game = try Game.init(allocator, 800, 600);
    try game.run();
    defer game.deinit();
}
