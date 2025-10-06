const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const SCREEN_WIDTH = @import("globals.zig").SCREEN_WIDTH;
const SCREEN_HEIGHT = @import("globals.zig").SCREEN_HEIGHT;
var passed_time: f32 = 0;

pub const Ship = struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    angle: f32, // in degrees
    size: f32,
    scale: f32,
    invincibility_timer: f32,
    dead: bool,
    hull:  [5] rl.Vector2,
    const ROTATION_SPEED = 300.0;
    const THRUST_POWER = 200.0;
    const FRICTION = 0.99;
    const HULL_THICKNESS = 2.0;
   pub const INVICIBLE_TIME = 3.0;

    pub fn init(x: f32, y:f32, should_be_invincible: bool) Ship{
        return Ship{
            .pos = rl.Vector2.init(x, y),
            .vel = rl.Vector2.init(0,0),
            .angle = 0, // point up
            .size = 12,
            .scale = 80.0,
            .invincibility_timer = if(should_be_invincible) INVICIBLE_TIME else 0.0,
            .dead = false,
            .hull = .{
                rl.Vector2{.x = 0, .y = -0.1}, // nose
                rl.Vector2{.x = 0.1, .y = 0.2}, // right bottom
                rl.Vector2{.x = 0.05, .y = 0.15}, // inner right corner
                rl.Vector2{.x = -0.05, .y = 0.15}, // inner left corner
                rl.Vector2{.x = -0.1, .y = 0.2}, // left bottom
            }
        };
    }
    pub fn update(self: *Ship, dt: f32) void{
        passed_time += dt;
        if(self.invincibility_timer > 0) {
            self.invincibility_timer -= dt;
        }
        self.handle_input(dt);
        self.apply_physics(dt);
        self.wrap_ship_around_screen();
    }
    fn handle_input(self: *Ship, dt: f32) void{
        if(rl.isKeyDown(rl.KeyboardKey.a) or rl.isKeyDown(rl.KeyboardKey.left)){
            self.angle -= ROTATION_SPEED * dt;
        }
        if(rl.isKeyDown(rl.KeyboardKey.d) or rl.isKeyDown(rl.KeyboardKey.right)){
            self.angle += ROTATION_SPEED * dt;
        }

        if(rl.isKeyDown(rl.KeyboardKey.w) or rl.isKeyDown(rl.KeyboardKey.up)){
            const rad = (self.angle - 90) * math.pi / 180.0;
            self.vel.x += @cos(rad) * THRUST_POWER * dt;
            self.vel.y += @sin(rad) * THRUST_POWER * dt;
        }
    }
    fn apply_physics(self: *Ship, dt: f32) void {
        self.pos.x += self.vel.x * dt;
        self.pos.y += self.vel.y * dt;

        self.vel.x *= Ship.FRICTION;
        self.vel.y *= Ship.FRICTION;
    }
    fn wrap_ship_around_screen(self: *Ship) void{
        self.pos.x = @mod(self.pos.x, SCREEN_WIDTH);
        self.pos.y = @mod(self.pos.y, SCREEN_HEIGHT);
    }
    fn get_transform(self: *const Ship, pos: rl.Vector2) rl.Vector2{
        const rad = self.angle * math.pi / 180.0;
        const rotation = rl.math.vector2Scale(rl.math.vector2Rotate(pos, rad), self.scale);

        return rl.Vector2{
            .x = (self.pos.x + rotation.x),
            .y = (self.pos.y + rotation.y),
        };
    }
    pub fn draw(self: *const Ship) void {
        // Ship Drawing
        for(0 .. self.hull.len) |i|{
            const p1 = self.get_transform(self.hull[i]);
            const p2 = self.get_transform(self.hull[(i + 1) % self.hull.len]);
            if(self.invincibility_timer > 0){
                //flicker hull
                const flicker_cycle = @mod(passed_time, 0.5);
                if(flicker_cycle < 0.25){
                    rl.drawLineEx(
                        p1,
                        p2,
                        Ship.HULL_THICKNESS,
                        rl.Color.white,
                    );
                }
            }else{
                rl.drawLineEx(
                    p1,
                    p2,
                    Ship.HULL_THICKNESS,
                    rl.Color.white,
                );
            }
        }
        // Flame Drawing
        if(rl.isKeyDown(rl.KeyboardKey.w) or rl.isKeyDown(rl.KeyboardKey.up)){
            const p_right = self.get_transform(rl.Vector2{.x = 0.065, .y = 0.25});
            const p_left = self.get_transform(rl.Vector2{.x = -0.065, .y = 0.25});
            const p_bottom = self.get_transform(rl.Vector2{.x = 0.0, .y = 0.45});
            const flicker_cycle = @mod(passed_time, 0.15);
            if (flicker_cycle < 0.03){
                rl.drawTriangle(p_right, p_left, p_bottom, rl.Color.orange);
            }
        }
    } // end of fn draw(...)
    pub fn get_gun_position(self: *const Ship) rl.Vector2{
        return self.get_transform(rl.Vector2{.x = 0, .y = -0.1}); // nose
    }
    pub fn get_angle(self: *Ship) f32{
        return self.angle;
    }
    pub fn kill(self: *Ship) void {
        self.dead = true;
    }
    pub fn is_dead(self:*const Ship) bool{
        return self.dead;
    }
    pub fn is_invicible(self: *const Ship) bool{
        return self.invincibility_timer > 0;
    }
};