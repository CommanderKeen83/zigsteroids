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


fn create_asteroids(number_of_asteroids: usize, random: std.Random, asteroids: *std.array_list.Managed(Asteroid)) !void{
    for(0 .. number_of_asteroids)|_|{
        var size: AsteroidSize = undefined;
        const rand_size = random.int(u8) % @typeInfo(AsteroidSize).@"enum".fields.len;
        size = @enumFromInt(rand_size);
        try asteroids.append(Asteroid.init_random_at_edge(size,random,));
    }
}

fn check_collision_circle(pos1: rl.Vector2, radius1: f32, pos2: rl.Vector2, radius2: f32) bool {
    const delta_x = pos1.x - pos2.x;
    const delta_y = pos1.y - pos2.y;
    const distance = @sqrt((delta_x * delta_x) + (delta_y * delta_y));
    if(distance < radius1 + radius2){
        return true;
    }
    return false;
}
pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var lives:i32 = 3;
    var is_game_over = false;
//    var score = 0;
    var wave: u8 = 1;
    var bullets = std.array_list.Managed(Bullet).init(allocator);
    defer bullets.deinit();
    var asteroids = std.array_list.Managed(Asteroid).init(allocator);
    defer asteroids.deinit();
    var temp_asteroids = std.array_list.Managed(Asteroid).init(allocator);
    defer temp_asteroids.deinit();

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context
                            //

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    var ship = Ship.init(SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0, false);
    var rng = std.Random.DefaultPrng.init(1234);
    const random = rng.random();
    try create_asteroids(6, random, &asteroids);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        const frametime = rl.getFrameTime();

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);

        if(rl.isKeyPressed(rl.KeyboardKey.space)){
            const pos = ship.get_gun_position();
            try bullets.append(Bullet.init(pos, ship.get_angle()));
        }
        // update
        if(ship.is_dead()){
            lives -= 1;
            if(lives == 0){
                is_game_over = true;
            }
            else{
                ship = Ship.init(SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0, true);
            }
        }
        if(is_game_over){
            rl.drawText(
                "Game over. Press r to restart",
                @intFromFloat(SCREEN_WIDTH / 2.0 - 150),
                @intFromFloat(SCREEN_HEIGHT / 2.0),
                10,
                rl.Color.dark_green,
            );
            if(rl.isKeyPressed(rl.KeyboardKey.r)){
                is_game_over = false;
                lives = 3;
                wave = 0;
                ship = Ship.init(SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0, false);
                asteroids.clearRetainingCapacity();
                try create_asteroids(6, random, &asteroids);
            }
            continue;
        }

        ship.update(frametime);
        for(asteroids.items)|*asteroid| {
            asteroid.update(frametime);
        }
        for(bullets.items) |*bullet|{
            bullet.update(frametime);
        }

        // Collision Detection
        temp_asteroids.clearRetainingCapacity();
        for(bullets.items) |*bullet|{
            for(asteroids.items)|*asteroid|{
                if(check_collision_circle(bullet.pos, bullet.size, asteroid.pos, asteroid.radius)){
                    if(asteroid.get_split_size())|asteroid_size|{
                        const pos = asteroid.pos;
                        const vel = asteroid.vel;
                        try temp_asteroids.append(Asteroid.init(pos, rl.Vector2{.x = vel.x + 10, .y = vel.y + 10 },asteroid_size, random));
                        try temp_asteroids.append(Asteroid.init(pos, rl.Vector2{.x = vel.x - 10, .y = vel.y - 10 },asteroid_size, random));
                    }
                    bullet.kill();
                    asteroid.kill();
                }
            }
        }
        try asteroids.appendSlice(temp_asteroids.items);

        if(!ship.is_invicible()){
            for(asteroids.items)|asteroid|{
                if(check_collision_circle(ship.pos, ship.size, asteroid.pos, asteroid.radius)){
                    ship.kill();
                    break;
                }
            }
        }

        //clean up
        var i: usize = bullets.items.len; // start at the end;
        while (i > 0){
            i -= 1; // go one back, otherwise we will be out of scope
            if(bullets.items[i].is_dead()){
                _ = bullets.swapRemove(i);
            }
        }
        var j = asteroids.items.len;
        while(j > 0){
            j -= 1;
            if(asteroids.items[j].is_dead()){
                _ = asteroids.swapRemove(j);
            }
        }
        if(asteroids.items.len == 0 and !is_game_over){
            wave += 1;
            try create_asteroids(6 * wave, random, &asteroids);
        }

        //Drawing
        for(asteroids.items)|*asteroid| {asteroid.draw();}
        for(bullets.items)|bullet|{bullet.draw();}

        var lives_buffer: [16]u8 = undefined;
        const lives_text = std.fmt.bufPrintZ(&lives_buffer, "Lives: {d}", .{lives}) catch "Lives ?";
        rl.drawText(lives_text, 10, 10, 10, rl.Color.dark_green);

        ship.draw();
    }
}
