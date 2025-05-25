const std = @import("std");
const rl = @import("raylib");
const math = std.math;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;
const ROTATION_SPEED = 1.5;
const SHIP_SPEED = 10.0;

const THICKNESS = 1.5;

const Ship = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    rotation: f32,
    deathtime: f32 = 0.0,
    pub fn isDeath(self: @This()) bool {
        return self.deathtime != 0.0;
    }
};
const Asteroid = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: AsteroidSize,
};

const AsteroidSize = enum { BIG, MEDIUM, SMALL };

const State = struct {
    now: f32,
    delta: f32,
    ship: Ship,
};
var state: State = .{
    .now = 0.0,
    .delta = 0.0,
    .ship = .{
        .position = rl.Vector2.init(400, 100),
        .velocity = rl.Vector2.init(0, 0.0),
        .rotation = 0.0,
    },
};

fn drawCoordinateGrid() void {
    rl.drawLineEx(
        rl.Vector2.init(SCREEN_WIDTH / 2.0, 0),
        rl.Vector2.init(SCREEN_WIDTH / 2, SCREEN_HEIGHT),
        1,
        rl.Color.blue,
    );
    rl.drawLineEx(
        rl.Vector2.init(0, SCREEN_HEIGHT / 2.0),
        rl.Vector2.init(SCREEN_WIDTH, SCREEN_HEIGHT / 2.0),
        1,
        rl.Color.blue,
    );
}

const localBoundariesShip = [_]rl.Vector2{
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
const localShipThruster = [_]rl.Vector2{
    rl.Vector2{ .x = -0.10, .y = -0.10 },
    rl.Vector2{ .x = 0.0, .y = -0.40 },
    rl.Vector2{ .x = 0.10, .y = -0.10 },
};
fn drawLines(origin: rl.Vector2, scale: f32, rotation: f32, points: []const rl.Vector2) void {
    const Transformer = struct {
        origin: rl.Vector2,
        scale: f32,
        rotation: f32,
        fn apply(self: @This(), position: rl.Vector2) rl.Vector2 {
            return rl.math.vector2Add(
                rl.math.vector2Rotate(rl.math.vector2Scale(position, self.scale), self.rotation),
                self.origin,
            );
        }
    };

    const transformer = Transformer{
        .origin = origin,
        .scale = scale,
        .rotation = rotation,
    };

    for (0..points.len) |i| {
        rl.drawLineEx(
            transformer.apply(points[i]),
            transformer.apply(points[(i + 1) % points.len]),
            THICKNESS,
            rl.Color.red,
        );
    }
}

fn update() void {
    state.delta = rl.getFrameTime();
    state.now += state.delta;
    processPlayerInput();

    const DRAG = 0.01;
    state.ship.velocity = rl.math.vector2Scale(state.ship.velocity, 1.0 - DRAG);
    state.ship.position = rl.math.vector2Add(state.ship.position, state.ship.velocity);
    state.ship.position = rl.Vector2.init(
        @mod(state.ship.position.x, SCREEN_WIDTH),
        @mod(state.ship.position.y, SCREEN_HEIGHT),
    );
}

fn render() void {
    // Draw Ship
    drawLines(
        state.ship.position,
        50,
        state.ship.rotation,
        &localBoundariesShip,
    );
    // Draw Ship Thruster
    if (rl.isKeyDown(rl.KeyboardKey.w) and @mod(@as(i32, @intFromFloat(state.now * 10)), 2) == 0) {
        drawLines(
            state.ship.position,
            50,
            state.ship.rotation,
            &localShipThruster,
        );
    }

    drawCoordinateGrid();
}

fn processPlayerInput() void {
    if (rl.isKeyDown(rl.KeyboardKey.a)) {
        state.ship.rotation -= state.delta * std.math.tau * ROTATION_SPEED;
    }
    if (rl.isKeyDown(rl.KeyboardKey.d)) {
        state.ship.rotation += state.delta * std.math.tau * ROTATION_SPEED;
    }
    if (rl.isKeyDown(rl.KeyboardKey.w)) {
        const adjusted_angle = state.ship.rotation + std.math.pi / 2.0;
        const shipDirection: rl.Vector2 = rl.Vector2.init(
            @cos(adjusted_angle),
            @sin(adjusted_angle),
        );
        state.ship.velocity = rl.math.vector2Add(
            state.ship.velocity,
            rl.math.vector2Scale(shipDirection, state.delta * SHIP_SPEED),
        );
    }
}

pub fn main() !void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Algebra");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        state.now += rl.getFrameTime();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.sky_blue);

        update();
        render();
    }
}
