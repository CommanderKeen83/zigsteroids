const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const SCREEN_WIDTH = @import("globals.zig").SCREEN_WIDTH;
const SCREEN_HEIGHT = @import("globals.zig").SCREEN_HEIGHT;


pub const Enemy = struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    radius: f32,
    direction_change_timer: f32,
    dead: bool,
    const SPEED = 80.0;
    const WRAP_BUFFER: f32 = 50.0;

    pub fn init(random: std.Random) Enemy{
        const side = random.int(u8) % 2; // give random number in the range from 0 to 255, either 0 or 1;
        var xpos: f32 = 0.0;
        var xvel: f32= 0.0;

        if(side == 0){ // left
            xpos = -WRAP_BUFFER;
            xvel = SPEED;
        }else{
            xpos = SCREEN_WIDTH + WRAP_BUFFER; // right
            xvel = -SPEED;
        }
        return Enemy{
            //.pos = rl.Vector2{.x = xpos, .y = random.float(f32) * SCREEN_HEIGHT, },
            .pos = rl.Vector2{.x = xpos, .y = random.float(f32) * SCREEN_HEIGHT, },
            .vel = rl.Vector2{.x = xvel, .y = 0, }, // default fly path is straight left or right, this will get adjusted in update-method
            .radius = 10.0,
            .direction_change_timer = 2.0,
            .dead = false,
        };
    }
    pub fn update(self: *Enemy, dt: f32) void {
        self.pos.x += self.vel.x * dt;
        self.pos.y += self.vel.y * dt;
        self.wrap_around_screen();
    }
    pub fn draw(self: *Enemy) void {
        rl.drawCircle(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), self.radius, rl.Color.magenta);
    }

    pub fn is_dead(self: *const Enemy) bool{
        return self.dead;
    }
    pub fn kill(self: *Enemy) void {
        self.dead = true;
    }
    fn wrap_around_screen(self: *Enemy) void{
        if(self.pos.x < -Enemy.WRAP_BUFFER) { self.pos.x = SCREEN_WIDTH + Enemy.WRAP_BUFFER; }
        if(self.pos.x > SCREEN_WIDTH + Enemy.WRAP_BUFFER) { self.pos.x = -Enemy.WRAP_BUFFER; }
        if(self.pos.y < -WRAP_BUFFER) { self.pos.y = SCREEN_HEIGHT + Enemy.WRAP_BUFFER; }
        if(self.pos.y > SCREEN_HEIGHT + Enemy.WRAP_BUFFER) { self.pos.y = -Enemy.WRAP_BUFFER; }
    }
};