const std = @import("std");
const rl = @import("raylib");

const allocator = std.heap.page_allocator;

const Vector2 = rl.Vector2;
const fg = rl.Color.white;
const bg = rl.Color.black;
const thickness: f32 = 1.0;
const shipWidth: f32 = 20;
const shipHeight: f32 = 40;
const screenWidth: f32 = 1200;
const screenHeight: f32 = 800;
const bulletSize: f32 = shipWidth / 4;

var bullets: std.ArrayList(Bullet) = undefined;
var planets: std.ArrayList(Planet) = undefined;

const Ship = struct {
    pos: Vector2,
    tail: bool,
    angle: f32,

    pub fn fire(self: *const Ship) void {
        const bullet: Bullet = .{
            .pos = Vector2.init(self.pos.x, self.pos.y).add(Vector2.init(0, -shipHeight / 2).rotate(self.angle)),
            .speed = 0,
            .accel = 0.1,
            .angle = self.angle,
            .firedAt = std.time.milliTimestamp(),
        };
        bullets.append(bullet) catch unreachable;
    }

    pub fn draw(self: *const Ship) void {
        const pivot = self.pos;

        const head = pivot.add(Vector2.init(0, -shipHeight / 2).rotate(self.angle));
        const leftBottom = pivot.add(Vector2.init(-shipWidth / 2, shipHeight / 2).rotate(self.angle));
        const rightBottom = pivot.add(Vector2.init(shipWidth / 2, shipHeight / 2).rotate(self.angle));
        const bottom = pivot.add(Vector2.init(0, shipHeight / 2.5).rotate(self.angle));

        const flamLT = pivot.add(Vector2.init(-shipWidth / 2.5, shipHeight / 2).rotate(self.angle));
        const flamLB = pivot.add(Vector2.init(0, shipHeight / 1.2).rotate(self.angle));
        const flamRT = pivot.add(Vector2.init(shipWidth / 2.5, shipHeight / 2).rotate(self.angle));
        const flamRB = pivot.add(Vector2.init(0, shipHeight / 1.2).rotate(self.angle));

        rl.drawLineEx(head, leftBottom, thickness, fg);
        rl.drawLineEx(head, rightBottom, thickness, fg);
        rl.drawLineEx(leftBottom, bottom, thickness, fg);
        rl.drawLineEx(rightBottom, bottom, thickness, fg);

        if (self.tail) {
            rl.drawLineEx(flamLT, flamLB, thickness, fg);
            rl.drawLineEx(flamLB, flamRB, thickness, fg);
            rl.drawLineEx(flamRT, flamRB, thickness, fg);
        }
    }
};

fn addPlanet() void {
    const random = std.crypto.random;
    const mplanet: Planet = .{
        .pos = Vector2.init(0, random.float(f32) * screenHeight),
        .width = 25,
        .height = 50,
        .speed = 0.6 + random.float(f32) * 0.6,
        .hits = 0,
        .firedAt = std.time.milliTimestamp(),
        .angle = @as(f32, std.math.pi) / @as(f32, 2),
    };
    planets.append(mplanet) catch unreachable;
}

const Bullet = struct {
    pos: Vector2,
    angle: f32,
    firedAt: i64,
    speed: f32,
    accel: f32,

    pub fn draw(self: *Bullet) void {
        self.pos = self.pos.add(
            Vector2.init(
                0,
                -self.speed,
            ).rotate(self.angle),
        );
        self.speed += self.accel;

        const x: i32 = @intFromFloat(self.pos.x);
        const y: i32 = @intFromFloat(self.pos.y);

        if (x < 0) return;
        if (x > screenWidth) return;
        if (y < 0) return;
        if (y > screenHeight) return;

        rl.drawCircle(x, y, bulletSize, fg);
    }
};

const Planet = struct {
    pos: Vector2,
    width: f32,
    height: f32,
    angle: f32,
    firedAt: i64,
    speed: f32,
    hits: u32,

    pub fn draw(self: *Planet) void {
        self.pos = self.pos.add(
            Vector2.init(
                0,
                -self.speed,
            ).rotate(self.angle),
        );

        const x: i32 = @intFromFloat(self.pos.x);
        const y: i32 = @intFromFloat(self.pos.y);

        if (x < 0 and x > screenWidth and y < 0 and y > screenHeight) return;

        rl.drawEllipse(x, y, self.height, self.width, fg);
    }
};

pub fn main() !void {
    std.debug.print("{}\n", .{Vector2.init(100, 100).rotate(0.01)});

    rl.initWindow(screenWidth, screenHeight, "Starship");
    defer rl.closeWindow();

    bullets = std.ArrayList(Bullet).init(allocator);
    defer bullets.deinit();
    planets = std.ArrayList(Planet).init(allocator);
    defer planets.deinit();

    rl.setTargetFPS(60);

    var ship: Ship = .{
        .pos = Vector2.init(screenWidth / 2, screenHeight / 2),
        .tail = false,
        .angle = 7 * std.math.pi / @as(f32, @floatFromInt(4)),
    };

    ship.fire();
    addPlanet();

    var lastKey: rl.KeyboardKey = .key_null;
    var score: i32 = 0;
    while (!rl.windowShouldClose()) {
        if (std.crypto.random.float(f32) < 0.005) {
            addPlanet();
        }
        var key = rl.getKeyPressed();
        ship.tail = false;
        if (rl.isKeyDown(lastKey)) {
            ship.tail = true;
            key = lastKey;
        }
        lastKey = key;
        switch (key) {
            .key_left, .key_h => {
                ship.angle -= 0.1;
            },
            .key_right, .key_l => {
                ship.angle += 0.1;
            },
            .key_space => {
                ship.fire();
            },
            else => {},
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        ship.draw();

        for (0..planets.items.len) |i| {
            if (planets.items[i].hits > 1) {
                score += 1;
                _ = planets.swapRemove(i);
                break;
            }
        }

        for (planets.items) |*planet| {
            planet.draw();
        }

        outer: while (true) {
            for (0..bullets.items.len) |i| {
                for (0..planets.items.len) |j| {
                    if (bullets.items[i].pos.x < planets.items[j].pos.x) continue;
                    if (bullets.items[i].pos.y < planets.items[j].pos.y) continue;
                    if (bullets.items[i].pos.x > planets.items[j].pos.x + planets.items[j].width) continue;
                    if (bullets.items[i].pos.y > planets.items[j].pos.y + planets.items[j].height) continue;
                    // std.debug.print("hit\n", .{});
                    _ = bullets.swapRemove(i);
                    planets.items[j].hits += 1;
                    break :outer;
                }
            }
            break;
        }

        for (bullets.items) |*bullet| {
            bullet.draw();
        }

        rl.drawText(
            rl.textFormat("Score: %i", .{score}),
            100,
            100,
            20,
            fg,
        );
    }
}
