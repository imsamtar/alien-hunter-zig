const std = @import("std");
const rl = @import("raylib");

const Vector = rl.Vector2;
const fg = rl.Color.white;
const bg = rl.Color.black;
const thickness: f32 = 1.0;
const shipWidth: f32 = 20;
const shipHeight: f32 = 40;
const screenWidth: f32 = 1200;
const screenHeight: f32 = 800;

const Ship = struct {
    pos: Vector,
    tail: bool,
};

fn drawShip(pos: Vector) void {
    const head: Vector = .{ .x = pos.x, .y = pos.y - shipHeight / 2 };
    const leftBottom: Vector = .{ .x = pos.x - shipWidth / 2, .y = pos.y + shipHeight / 2 };
    const rightBottom: Vector = .{ .x = pos.x + shipWidth / 2, .y = pos.y + shipHeight / 2 };
    const bottom: Vector = .{ .x = pos.x, .y = pos.y + shipHeight / 2.5 };
    const flamLT: Vector = .{ .x = pos.x - shipWidth / 2.5, .y = pos.y + shipHeight / 2 };
    const flamLB: Vector = .{ .x = pos.x, .y = pos.y + shipHeight / 1.2 };
    const flamRT: Vector = .{ .x = pos.x + shipWidth / 2.5, .y = pos.y + shipHeight / 2 };
    const flamRB: Vector = .{ .x = pos.x, .y = pos.y + shipHeight / 1.2 };
    rl.drawLineEx(head, leftBottom, thickness, fg);
    rl.drawLineEx(head, rightBottom, thickness, fg);
    rl.drawLineEx(leftBottom, bottom, thickness, fg);
    rl.drawLineEx(rightBottom, bottom, thickness, fg);

    rl.drawLineEx(flamLT, flamLB, thickness, fg);
    rl.drawLineEx(flamLB, flamRB, thickness, fg);
    rl.drawLineEx(flamRT, flamRB, thickness, fg);
}

pub fn main() !void {
    rl.initWindow(screenWidth, screenHeight, "Starship");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    const ship: Ship = .{
        .pos = .{
            .x = screenWidth / 2,
            .y = screenHeight / 2,
        },
        .tail = false,
    };
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        // rl.drawLineEx(.{ .x = 0, .y = 0 }, .{ .x = 100, .y = 100 }, thickness, rl.Color.white);
        drawShip(ship.pos);
    }
}
