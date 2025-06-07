const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const entities = @import("entities.zig");
const Ship = entities.Ship;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;

const THICKNESS = 1.5;

const State = struct {
    now: f32,
    delta: f32,
    ship: Ship,
};
// global state object
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

pub const Game = struct {
    width: i32,
    height: i32,
    pub fn init(l_width: i32, l_height: i32) !Game {
        rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Algebra");
        rl.setTargetFPS(60);
        return .{
            .width = l_width,
            .height = l_height,
        };
    }
    pub fn deinit(self: Game) void {
        _ = self;
        rl.closeWindow();
    }
    fn processPlayerInput(self: Game) void {
        _ = self;
        if (rl.isKeyDown(rl.KeyboardKey.a)) {
            state.ship.rotation -= state.delta * std.math.tau * entities.ROTATION_SPEED;
        }
        if (rl.isKeyDown(rl.KeyboardKey.d)) {
            state.ship.rotation += state.delta * std.math.tau * entities.ROTATION_SPEED;
        }
        if (rl.isKeyDown(rl.KeyboardKey.w)) {
            const adjusted_angle = state.ship.rotation + std.math.pi / 2.0;
            const shipDirection: rl.Vector2 = rl.Vector2.init(
                @cos(adjusted_angle),
                @sin(adjusted_angle),
            );
            state.ship.velocity = rl.math.vector2Add(
                state.ship.velocity,
                rl.math.vector2Scale(shipDirection, state.delta * entities.SHIP_SPEED),
            );
        }
    }
    pub fn update(self: @This()) void {
        state.delta = rl.getFrameTime();
        state.now += state.delta;
        self.processPlayerInput();

        const DRAG = 0.01;
        state.ship.velocity = rl.math.vector2Scale(state.ship.velocity, 1.0 - DRAG);
        state.ship.position = rl.math.vector2Add(state.ship.position, state.ship.velocity);

        state.ship.position = rl.Vector2.init(
            @mod(state.ship.position.x, SCREEN_WIDTH),
            @mod(state.ship.position.y, SCREEN_HEIGHT),
        );
    }
    pub fn render(self: @This()) void {
        _ = self;
        drawLines(
            state.ship.position,
            50,
            state.ship.rotation,
            &entities.localBoundariesShip,
        );
        // Draw Ship Thruster
        if (rl.isKeyDown(rl.KeyboardKey.w) and @mod(@as(i32, @intFromFloat(state.now * 10)), 2) == 0) {
            drawLines(
                state.ship.position,
                50,
                state.ship.rotation,
                &entities.localShipThruster,
            );
        }
        drawCoordinateGrid();
    }
    pub fn run(self: @This()) !void {
        while (!rl.windowShouldClose()) {
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(rl.Color.sky_blue);

            self.update();
            self.render();
        }
    }
};
