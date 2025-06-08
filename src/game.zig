const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const entities = @import("entities.zig");
const Ship = entities.Ship;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;

const State = struct {
    now: f32,
    delta: f32,
    ship: Ship,
    projectiles: std.ArrayList(entities.Projectile),
};
// global state object

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
fn drawProjectiles(pos: rl.Vector2) void {
    rl.drawCircleV(pos, 1.0, rl.Color.red);
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
            entities.THICKNESS,
            rl.Color.red,
        );
    }
}

pub const Game = struct {
    width: i32,
    height: i32,
    state: State,
    pub fn init(allocator: std.mem.Allocator, l_width: i32, l_height: i32) !Game {
        rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Algebra");
        rl.setTargetFPS(60);
        return .{
            .width = l_width,
            .height = l_height,
            .state = .{
                .now = 0.0,
                .delta = 0.0,
                .ship = .{
                    .position = rl.Vector2.init(400, 100),
                    .velocity = rl.Vector2.init(0, 0.0),
                    .rotation = 0.0,
                },
                .projectiles = std.ArrayList(entities.Projectile).init(allocator),
            },
        };
    }
    pub fn deinit(self: *Game) void {
        _ = self;
        rl.closeWindow();
    }
    fn processPlayerInput(self: *Game) void {
        if (rl.isKeyDown(rl.KeyboardKey.a)) {
            self.state.ship.rotation -= self.state.delta * std.math.tau * entities.ROTATION_SPEED;
        }
        if (rl.isKeyDown(rl.KeyboardKey.d)) {
            self.state.ship.rotation += self.state.delta * std.math.tau * entities.ROTATION_SPEED;
        }
        if (rl.isKeyDown(rl.KeyboardKey.w)) {
            self.state.ship.velocity = rl.math.vector2Add(
                self.state.ship.velocity,
                rl.math.vector2Scale(self.state.ship.getDirection(), self.state.delta * entities.SHIP_SPEED),
            );
        }
        if (rl.isKeyDown(rl.KeyboardKey.space)) {}
    }
    pub fn update(self: *Game) void {
        self.state.delta = rl.getFrameTime();
        self.state.now += self.state.delta;
        self.processPlayerInput();

        const DRAG = 0.01;
        self.state.ship.velocity = rl.math.vector2Scale(self.state.ship.velocity, 1.0 - DRAG);
        self.state.ship.position = rl.math.vector2Add(self.state.ship.position, self.state.ship.velocity);

        self.state.ship.position = rl.Vector2.init(
            @mod(self.state.ship.position.x, SCREEN_WIDTH),
            @mod(self.state.ship.position.y, SCREEN_HEIGHT),
        );
    }
    pub fn render(self: *Game) void {
        drawLines(
            self.state.ship.position,
            50,
            self.state.ship.rotation,
            &entities.localBoundariesShip,
        );
        // Draw Ship Thruster
        if (rl.isKeyDown(rl.KeyboardKey.w) and @mod(@as(i32, @intFromFloat(self.state.now * 10)), 2) == 0) {
            drawLines(
                self.state.ship.position,
                50,
                self.state.ship.rotation,
                &entities.localShipThruster,
            );
        }
        drawCoordinateGrid();
    }
    pub fn run(self: *Game) !void {
        while (!rl.windowShouldClose()) {
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(rl.Color.sky_blue);

            self.update();
            self.render();
        }
    }
};
