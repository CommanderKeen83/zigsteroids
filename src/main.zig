const Game = @import("game.zig").Game;

pub fn main() !void {
    var game: Game = try Game.init(800, 600);
    try game.run();
    defer game.deinit();
}
