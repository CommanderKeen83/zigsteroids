// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const std = @import("std");
const math = std.math;
const Ship = @import("ship.zig").Ship;
const Bullet = @import("bullet.zig").Bullet;
const Asteroid = @import("asteroid.zig").Asteroid;
const AsteroidSize = @import("asteroid.zig").AsteroidSize;
const SCREEN_WIDTH = @import("globals.zig").SCREEN_WIDTH;
const SCREEN_HEIGHT = @import("globals.zig").SCREEN_HEIGHT;
pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var bullets = std.array_list.Managed(Bullet).init(allocator);
    var asteroids = std.array_list.Managed(Asteroid).init(allocator);

    defer bullets.deinit();

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    var ship = Ship.init(SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0);
    var rng = std.Random.DefaultPrng.init(1234);
    const random = rng.random();
    for(0 .. 6)|_|{
        var size: AsteroidSize = undefined;
        const rand_size = random.int(u8) % @typeInfo(AsteroidSize).@"enum".fields.len;
        size = @enumFromInt(rand_size);
        try asteroids.append(Asteroid.init_random_at_edge(
            size,
            random,
            )
        );
    }

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        const frametime = rl.getFrameTime();
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);

        if(rl.isKeyPressed(rl.KeyboardKey.space)){
            const pos = ship.get_gun_position();
            try bullets.append(Bullet.init(pos, ship.get_angle()));
        }
        ship.update(frametime);
        for(bullets.items) |*bullet|{
            bullet.update(frametime);
            bullet.draw();
        }
        var i: usize = bullets.items.len; // start at the end;
        while (i > 0){
            i -= 1; // go one back, otherwise we will be out of scope when
            if(bullets.items[i].is_dead()){
                _ = bullets.swapRemove(i);
            }
        }
        for(asteroids.items)|*asteroid| {
            asteroid.update(frametime);
            asteroid.draw();
        }
        ship.draw();
    }
}
