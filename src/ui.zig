const std = @import("std");
const rl = @import("raylib");

const HealthColor = enum {
    DarkGreen,
    Lime,
    Green,
    Yellow,
    Gold,
    Orange,
    Red,
    Maroon,
    fn getColorFromHealth(health: u8) HealthColor {
        if (health > 80) {
            return .DarkGreen;
        }
        return .Maroon;
    }
};
pub const PlayerHealthBar = struct {
    maxHealth: u16,
    currentHealth: u16,
    position: rl.Vector2 = rl.Vector2.init(0, 0),
    size: rl.Vector2 = rl.Vector2.init(300, 100),
    color: HealthColor = HealthColor.DarkGreen,
};
