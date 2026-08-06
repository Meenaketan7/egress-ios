import SwiftUI

// MARK: - QuizRobot

/// The quiz's mascot — a full-body pixel robot drawn to the Learn reference art: a green antenna, a tan
/// head with a dark visor of little green LEDs and side "ears", a wider torso with darker shoulders and a
/// row of three green chest lights, all sitting on a soft oval shadow. Pure vector pixels (a coloured
/// bitmap in a `Canvas`), so it stays crisp at any size. Distinct from the simulation's `RallyRobot`, which
/// keeps its own 9×9 chassis.
struct QuizRobot: View {
    /// Rendered width; the robot is a touch taller than wide (it includes the shadow).
    var width: CGFloat = 64
    /// Tint for the antenna, visor LEDs and chest lights — the robot "reacts" (red on a wrong answer).
    var accent: Color = .egDataGreen

    private static let columns = 14
    /// `.` clear · `a` antenna · `h` body tan · `d` shoulder/shade · `v` visor · `g` green light.
    private static let rows = [
        "......aa......",
        "......aa......",
        "......aa......",
        "...hhhhhhhh...",
        "..hhhhhhhhhh..",
        "..hhhhhhhhhh..",
        "..hvvvvvvvvh..",
        ".dhvgvgvgvvhd.",
        "..hvvvvvvvvh..",
        "..hhhhhhhhhh..",
        "...hhhhhhhh...",
        ".ddhhhhhhhhdd.",
        ".ddhghghghhdd.",
        ".ddhhhhhhhhdd.",
        "...hhhhhhhh...",
    ]

    private static let bodyTan = Color(hex: 0xCBB899) // egRallyBody
    private static let shadeTan = Color(hex: 0xAE9B76) // darker tan — shoulders, ears
    private static let shadow = Color(hex: 0xC7CFAF) // pale sage base

    var body: some View {
        Canvas { context, size in
            let cell = size.width / CGFloat(Self.columns)

            // Soft oval shadow under the feet, drawn first so the body sits on it.
            let shadowRect = CGRect(
                x: cell * 2.6, y: cell * 14.3,
                width: cell * 8.8, height: cell * 1.9
            )
            context.fill(Path(ellipseIn: shadowRect), with: .color(Self.shadow))

            for (row, line) in Self.rows.enumerated() {
                for (col, ch) in line.enumerated() where ch != "." {
                    let colour: Color = switch ch {
                    case "a", "g": accent
                    case "d": Self.shadeTan
                    case "v": .egCanvasBase
                    default: Self.bodyTan
                    }
                    let rect = CGRect(
                        x: CGFloat(col) * cell,
                        y: CGFloat(row) * cell,
                        width: cell + 0.5, height: cell + 0.5
                    )
                    context.fill(Path(rect), with: .color(colour))
                }
            }
        }
        .frame(width: width, height: width * 17 / CGFloat(Self.columns))
        .accessibilityHidden(true)
    }
}

// MARK: - PixelHeart

/// A single 8-bit life heart — a solid terracotta pixel heart when full, a muted tan one when spent
/// (design: the quiz hearts). Drawn as squares so it matches the app's pixel chrome.
struct PixelHeart: View {
    var filled: Bool
    var size: CGFloat = 20

    private static let rows = [
        ".##.##.",
        "#######",
        "#######",
        "#######",
        ".#####.",
        "..###..",
        "...#...",
    ]

    var body: some View {
        Canvas { context, canvas in
            let cell = canvas.width / 7
            let colour = filled ? Color.egAccentTerracotta : Color.egSeparator
            for (row, line) in Self.rows.enumerated() {
                for (col, ch) in line.enumerated() where ch == "#" {
                    let rect = CGRect(
                        x: CGFloat(col) * cell,
                        y: CGFloat(row) * cell,
                        width: cell + 0.5, height: cell + 0.5
                    )
                    context.fill(Path(rect), with: .color(colour))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - BubbleTail

/// The speech-bubble pointer aimed at the robot — a small triangle filled with the bubble's surface, with
/// only its two slanted edges outlined so it reads as an extension of the bubble's border (design: the
/// question card). Placed on the bubble's leading edge, overlapping its border by a hair.
struct BubbleTail: View {
    var body: some View {
        ZStack {
            TailShape(closed: true).fill(Color.egSurfaceRaised)
            TailShape(closed: false).stroke(Color.egOutline, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        }
        .frame(width: 12, height: 18)
        .accessibilityHidden(true)
    }

    private struct TailShape: Shape {
        /// Closed for the fill; open (only the two slanted edges) for the border, so the base that meets
        /// the bubble isn't stroked.
        var closed: Bool

        func path(in r: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: r.maxX, y: r.minY))
            path.addLine(to: CGPoint(x: r.minX, y: r.midY))
            path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            if closed { path.closeSubpath() }
            return path
        }
    }
}

// MARK: - PixelPlus

/// A tiny 3×3 pixel sparkle (a plus) — the gold flecks around the CORRECT! banner.
struct PixelPlus: View {
    var color: Color
    var unit: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let u = size.width / 3
            for (col, row) in [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)] {
                let rect = CGRect(x: CGFloat(col) * u, y: CGFloat(row) * u, width: u + 0.5, height: u + 0.5)
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: unit * 3, height: unit * 3)
        .accessibilityHidden(true)
    }
}
