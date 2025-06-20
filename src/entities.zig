const rl = @import("raylib");
const std = @import("std");
pub const ROTATION_SPEED = 1.5;
pub const PROJECTILE_SPEED = 200.0;
pub const SHIP_SPEED = 10.0;
pub const THICKNESS = 1.5;

const Asteroid = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: AsteroidSize,
};
pub const Projectile = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
};
const AsteroidSize = enum { BIG, MEDIUM, SMALL };

pub const Ship = struct {
    position: rl.Vector2,
    velocity: rl.Vector2 = rl.Vector2.init(0, 0),
    rotation: f32 = 0.0,
    deathtime: f32 = 0.0,

    pub fn isDeath(self: @This()) bool {
        return self.deathtime != 0.0;
    }
    pub fn getDirection(self: Ship) rl.Vector2 {
        const adjusted_angle = self.rotation + std.math.pi / 2.0;
        return rl.Vector2.init(
            @cos(adjusted_angle),
            @sin(adjusted_angle),
        );
    }
};
pub const localBoundariesShip = [_]rl.Vector2{
    rl.Vector2{ .x = -0.30, .y = -0.20 },
    rl.Vector2{ .x = -0.10, .y = -0.10 },
    rl.Vector2{ .x = 0.10, .y = -0.10 },
    rl.Vector2{ .x = 0.30, .y = -0.20 },
    rl.Vector2{ .x = 0.30, .y = 0.10 },
    rl.Vector2{ .x = 0.20, .y = 0.10 },
    rl.Vector2{ .x = 0.0, .y = 0.30 },
    rl.Vector2{ .x = -0.20, .y = 0.10 },
    rl.Vector2{ .x = -0.30, .y = 0.10 },
};
pub const localShipThruster = [_]rl.Vector2{
    rl.Vector2{ .x = -0.10, .y = -0.10 },
    rl.Vector2{ .x = 0.0, .y = -0.40 },
    rl.Vector2{ .x = 0.10, .y = -0.10 },
};
