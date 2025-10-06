const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const SCREEN_WIDTH = @import("globals.zig").SCREEN_WIDTH;
const SCREEN_HEIGHT = @import("globals.zig").SCREEN_HEIGHT;
pub const AsteroidSize = enum {
    Large,
    Medium,
    Small,
};
const ScreenEdge = enum{
    Top,
    Left,
    Right,
    Bottom,
};

pub const Asteroid = struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    rotation: f32,
    rotation_speed: f32,
    radius: f32,
    size: AsteroidSize,
    dead: bool,
    shape: [8]rl.Vector2,
    const BASE_SPEED = 50.0;
    const LARGE_RADIUS = 50.0;
    const MEDIUM_RADIUS = 25.0;
    const SMALL_RADIUS = 15.0;

    const SHAPE_POINTS = 8; // Determines how many corners/edges the asteroid has!
// SHAPE_MIN/MAX_RADIUS_RATIO controls how JAGGED the asteroid looks:
// lets say a LARGE_RADIUS Asteroid with 50 pixels:
// Some points are close to the center (70% of radius = 35 pixels)
// Some points are far of the center ( 100 % of the radius = 50 pixel)
    const SHAPE_MIN_RADIUS_RATIO = 0.6;
    const SHAPE_MAX_RADIUS_RATIO = 1.0;

    pub fn init(
        pos: rl.Vector2,
        vel: rl.Vector2,
        size: AsteroidSize,
        random: std.Random,
    ) Asteroid{
        const radius:f32 = switch(size){
            .Large =>  LARGE_RADIUS,
            .Medium => MEDIUM_RADIUS,
            .Small =>  SMALL_RADIUS
        };
        var shape: [SHAPE_POINTS]rl.Vector2 = undefined;
        for(0 .. 8)  |i|{
            const fraction_of_circle: f32 = @as(f32, @floatFromInt(i)) / 8.0;
            const angle: f32 = fraction_of_circle * 2.0 * math.pi; // angle is the direction (in radians) where this point should be placed around the circle
            // Calculate random radius (THE JAGGEDNESS!)
            const radius_variation = SHAPE_MAX_RADIUS_RATIO - SHAPE_MIN_RADIUS_RATIO;
            const random_factor = random.float(f32) * radius_variation;
            const radius_ratio = SHAPE_MIN_RADIUS_RATIO + random_factor;
            // contains the distance from center to somewhere in the space from
            // SHAPE_MIN_RADIUS_RATIO to SHAPE_MAX_RADIUS_RATIO which would be the radius itsself (Large/Medium/Small)
            const r = radius_ratio * radius;
            shape[i] = rl.Vector2{
                .x = @cos(angle) * r,
                .y = @sin(angle) * r,
            };
        }
        return Asteroid{
            .pos = pos,
            .vel = vel,
            .rotation = 5.0,
            .rotation_speed = 5.0,
            .radius = radius,
            .size = size,
            .dead = false,
            .shape = shape,
        };
    }
    pub fn init_random_at_edge(size: AsteroidSize, random: std.Random,) Asteroid{
        var pos: rl.Vector2 = undefined;
        var vel: rl.Vector2 = undefined;

        const edge_int = random.int(u8) % @typeInfo(ScreenEdge).@"enum".fields.len;
        const screen_edge: ScreenEdge = @enumFromInt(edge_int);

//  if the asteroid spawns outside the screen, it must move towards the center of the screen
//  meaning when
//  spawned on Top: move down (positive y)
//  spawned on Bottom: move up (negative y)
//  spawned on Left:  move right (positive x)
//  spawned on Right: move left (negative x)

        switch (screen_edge){
            .Top => {
                pos = rl.Vector2{
                    .x = random.float(f32) * SCREEN_WIDTH,
                    .y = -LARGE_RADIUS
                };
                vel = rl.Vector2{
                    .x = (random.float(f32) - 0.5) * BASE_SPEED * 2.0,
                    .y = random.float(f32) * BASE_SPEED
                };
            },
            .Left => {
                pos = rl.Vector2{
                    .x = -LARGE_RADIUS,
                    .y = random.float(f32) * SCREEN_HEIGHT,
                };
                vel = rl.Vector2{
                    .x = random.float(f32) * BASE_SPEED,
                    .y = (random.float(f32) - 0.5) * BASE_SPEED * 2.0,
                };
            },
            .Right =>{
                pos = rl.Vector2{
                    .x = SCREEN_WIDTH + LARGE_RADIUS,
                    .y = random.float(f32) * SCREEN_HEIGHT,
                };
                vel = rl.Vector2{
                    .x = random.float(f32) * -BASE_SPEED,
                    .y = (random.float(f32) - 0.5) * BASE_SPEED * 2.0,
                };
            },
            .Bottom =>{
                pos = rl.Vector2{
                    .x = random.float(f32) * SCREEN_WIDTH,
                    .y = SCREEN_HEIGHT + LARGE_RADIUS,
                };
                vel = rl.Vector2{
                    .x = (random.float(f32) - 0.5) * BASE_SPEED * 2.0,
                    .y = random.float(f32) * -BASE_SPEED,
                };
            },
        }
        return init(pos, vel, size, random);
    }
    pub fn kill(self: *Asteroid) void{
        self.dead = true;
    }
    pub fn is_dead(self: * const Asteroid) bool{
        return self.dead;
    }
    fn wrap_ship_around_screen(self: *Asteroid) void{
        const WRAP_BUFFER = 50;
        if(self.pos.x < -WRAP_BUFFER) { self.pos.x = SCREEN_WIDTH + WRAP_BUFFER; }
        if(self.pos.x > SCREEN_WIDTH + WRAP_BUFFER) { self.pos.x = -WRAP_BUFFER; }
        if(self.pos.y < -WRAP_BUFFER) { self.pos.y = SCREEN_HEIGHT + WRAP_BUFFER; }
        if(self.pos.y > SCREEN_HEIGHT + WRAP_BUFFER) {self.pos.y = -WRAP_BUFFER; }
    }
    pub fn get_split_size(self: * const Asteroid) ?AsteroidSize{
        return switch(self.size){
            .Large => .Medium,
            .Medium => .Small,
            .Small => null
        };
    }
    pub fn update(self: *Asteroid, dt: f32) void{
        self.rotation += self.rotation_speed * dt;
        self.pos.x += self.vel.x * dt;
        self.pos.y += self.vel.y * dt;

        self.wrap_ship_around_screen();
    }
    pub fn draw(self: *const Asteroid) void{
        for(0 .. self.shape.len)|i|{
            const next_i = (i + 1) % self.shape.len;
            const rad = self.rotation * math.pi / 180.0;

            const p1_rotated = rl.math.vector2Rotate(self.shape[i], rad);
            const p2_rotated = rl.math.vector2Rotate(self.shape[next_i], rad);

            const world_pos1 = rl.math.vector2Add(p1_rotated, self.pos);
            const world_pos2 = rl.math.vector2Add(p2_rotated, self.pos);

            rl.drawLineEx(
                world_pos1,
                world_pos2,
                1,
                rl.Color.white,
            );
        }
    }
};