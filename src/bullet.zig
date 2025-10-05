const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const SCREEN_WIDTH = @import("globals.zig").SCREEN_WIDTH;
const SCREEN_HEIGHT = @import("globals.zig").SCREEN_HEIGHT;

pub const Bullet = struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    lifetime: f32,
    size: f32,
    dead: bool,
    pub const SPEED = 300.0;
    const MAX_LIFETIME = 2.0;
    pub fn init(pos: rl.Vector2, angle: f32) Bullet{
        const rad = (angle - 90) * math.pi / 180.0;
        return Bullet{
            .pos = pos,
            .vel = rl.Vector2{.x = @cos(rad) * Bullet.SPEED, .y = @sin(rad) * Bullet.SPEED},
            .lifetime = 0.0,
            . size = 2.0,
            .dead = false,
        };
    }
    pub fn is_dead(self: *const Bullet) bool{
        return self.dead or self.lifetime > Bullet.MAX_LIFETIME;
    }
    pub fn kill(self: *Bullet) void{
        self.dead = true;
    }
    pub fn update(self: *Bullet, dt: f32) void{
        self.lifetime += dt;
        self.pos = rl.math.vector2Add(
            self.pos,
            rl.Vector2{
                .x = self.vel.x * dt,
                .y = self.vel.y * dt,
            }
        );

    }
    pub fn draw(self: *const Bullet) void{
        rl.drawCircle(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), self.size, rl.Color.white);
    }
};