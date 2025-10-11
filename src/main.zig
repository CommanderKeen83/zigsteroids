// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const std = @import("std");
const math = std.math;
const Ship = @import("ship.zig").Ship;
const Bullet = @import("bullet.zig").Bullet;
const Asteroid = @import("asteroid.zig").Asteroid;
const Enemy = @import("enemy.zig").Enemy;
const AsteroidSize = @import("asteroid.zig").AsteroidSize;
const SCREEN_WIDTH = @import("globals.zig").SCREEN_WIDTH;
const SCREEN_HEIGHT = @import("globals.zig").SCREEN_HEIGHT;


fn create_asteroids(number_of_asteroids: usize, wave: u8, random: std.Random, asteroids: *std.array_list.Managed(Asteroid)) !void{
    for(0 .. number_of_asteroids)|_|{
        var size: AsteroidSize = undefined;
        const rand_size = random.int(u8) % @typeInfo(AsteroidSize).@"enum".fields.len;
        size = @enumFromInt(rand_size);
        const speed_multiplier: f32 = @floatFromInt(wave);
        try asteroids.append(Asteroid.init_random_at_edge(size,random, speed_multiplier));
    }
}
fn get_direction_to_player(player_position: rl.Vector2, enemy_position: rl.Vector2) rl.Vector2{
    return rl.math.vector2Normalize(rl.math.vector2Subtract(player_position, enemy_position));
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
    var score: i32 = 0;
    var wave: u8 = 1;
    var bullets = std.array_list.Managed(Bullet).init(allocator);
    defer bullets.deinit();
    var enemy_bullets = std.array_list.Managed(Bullet).init(allocator);
    defer enemy_bullets.deinit();
    var enemies = std.array_list.Managed(Enemy).init(allocator);
    defer enemies.deinit();
    var asteroids = std.array_list.Managed(Asteroid).init(allocator);
    defer asteroids.deinit();
    var temp_asteroids = std.array_list.Managed(Asteroid).init(allocator);
    defer temp_asteroids.deinit();

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    var ship = Ship.init(SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0, false);
    var rng = std.Random.DefaultPrng.init(1234);
    const random = rng.random();
    try create_asteroids(6, wave, random, &asteroids);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        const frametime = rl.getFrameTime();

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);

        if(rl.isKeyPressed(rl.KeyboardKey.space)){
            const pos = ship.get_gun_position();
            try bullets.append(Bullet.init_with_angle(pos, ship.get_angle()));
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
            var score_buffer: [16]u8 = undefined;
            const score_text = std.fmt.bufPrintZ(&score_buffer, "Score: {d}", .{score}) catch "Score ?";
            rl.drawText(score_text,
                @intFromFloat(SCREEN_WIDTH / 2.0 - 150),
                @intFromFloat(@as(f32, SCREEN_HEIGHT / 2.0) + 12),
                10,
                rl.Color.dark_green);

            var wave_score_buffer: [16]u8 = undefined;
            const wave_text = std.fmt.bufPrintZ(&wave_score_buffer, "Wave: {d}", .{wave}) catch "Wave ?";
            rl.drawText(wave_text,
                @intFromFloat(SCREEN_WIDTH / 2.0 - 150),
                @intFromFloat(@as(f32,(SCREEN_HEIGHT / 2.0)) + 24),
                10,
                rl.Color.dark_green);

            if(rl.isKeyPressed(rl.KeyboardKey.r)){
                is_game_over = false;
                lives = 3;
                wave = 1;
                score = 0;
                ship = Ship.init(SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0, false);
                asteroids.clearRetainingCapacity();
                enemies.clearRetainingCapacity();
                bullets.clearRetainingCapacity();
                enemy_bullets.clearRetainingCapacity();
                try create_asteroids(6, wave, random, &asteroids);
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
        for(enemy_bullets.items) |*bullet|{
            bullet.update(frametime);
        }
        if(wave > 2 and enemies.items.len == 0){
            try enemies.append(Enemy.init(random));

        }
        for(enemies.items) |*enemy|{
            enemy.update(frametime);
            if(enemy.ready_to_shoot()){
                const direction = get_direction_to_player(ship.pos, enemy.pos);
                try enemy_bullets.append(Bullet.init_with_velocity(enemy.pos, direction));
                enemy.reload_weapon();
            }
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
                    score += 10 * wave;
                }
            }
            for(enemies.items) | *enemy |{
                if(check_collision_circle(bullet.pos, bullet.size, enemy.pos,enemy.radius)){
                    enemy.kill();
                    score += 30 * wave;
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
            for(enemies.items)|enemy|{
                if(check_collision_circle(ship.pos, ship.size, enemy.pos, enemy.radius)){
                    ship.kill();
                    break;
                }
            }
            for(enemy_bullets.items)|bullet|{
                if(check_collision_circle(ship.pos, ship.size, bullet.pos, bullet.size)){
                    ship.kill();
                    break;
                }
            }
        }

        //clean up
        var k: usize = enemies.items.len;
        while (k > 0){
            k -=1;
            if(enemies.items[k].is_dead()){

                _ = enemies.swapRemove(k);
            }
        }
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
            try create_asteroids(6 * wave, wave, random, &asteroids);
        }

        //Drawing
        for(asteroids.items)|*asteroid| {asteroid.draw();}
        for(bullets.items)|bullet|{bullet.draw();}
        for(enemy_bullets.items)|bullet|{bullet.draw();}
        for(enemies.items)|*enemy| {enemy.draw();}

        var lives_buffer: [16]u8 = undefined;
        const lives_text = std.fmt.bufPrintZ(&lives_buffer, "Lives: {d}", .{lives}) catch "Lives ?";
        rl.drawText(lives_text, 10, 10, 10, rl.Color.dark_green);

        ship.draw();
    }
}
