import EgressEngine
import SwiftUI

/// Static drawing of a venue's *built* geometry — the dot grid, walls, obstacle footprints and exit
/// spans — shared by the live simulation canvas (`SimulationRenderer`) and the parametric editor
/// (`EditorCanvasView`). Pure and stateless: the same venue always paints the same scenery, so the
/// picture the user authors in the editor is pixel-for-pixel the picture the simulation runs on.
enum VenueScenery {
    /// The 0.25 m dot grid, with every 4th dot (1 m) brightened — the canvas's base texture.
    static func drawGrid(venue: VenueModel, projection: CanvasProjection, into context: inout GraphicsContext) {
        let cell = venue.geometry.cellSize
        let dot: CGFloat = 1.5
        var minor = Path()
        var major = Path()
        for gridY in 0 ... venue.geometry.size.height {
            for gridX in 0 ... venue.geometry.size.width {
                let centre = projection.point(Vec2(Double(gridX) * cell, Double(gridY) * cell))
                let rect = CGRect(x: centre.x - dot / 2, y: centre.y - dot / 2, width: dot, height: dot)
                if gridX % 4 == 0, gridY % 4 == 0 {
                    major.addEllipse(in: rect)
                } else {
                    minor.addEllipse(in: rect)
                }
            }
        }
        context.fill(minor, with: .color(.egCanvasGrid))
        context.fill(major, with: .color(.egCanvasGridMajor))
    }

    /// Impassable wall segments — solid structural strokes, drawn a touch wider than a person so a
    /// walled throat visibly pinches the crowd. This is what the engine rasterises into blocked cells.
    static func drawWalls(_ walls: [Wall], projection: CanvasProjection, into context: inout GraphicsContext) {
        guard !walls.isEmpty else { return }
        let width = max(3, projection.length(SafetyStandards.cellSize * 1.6))
        var path = Path()
        for wall in walls {
            path.move(to: projection.point(wall.a))
            path.addLine(to: projection.point(wall.b))
        }
        context.stroke(
            path,
            with: .color(.egPropStructuralOutline),
            style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        )
    }

    /// Obstacle boxes, drawn in one of three chrome treatments so the simulation class reads at a
    /// glance (design's PROP LIBRARY): relocatable furniture has a lit top edge + corner grip-dots
    /// ("the coach may move these"); structural props carry a heavier outline + a cyan anchor notch
    /// ("fixed — routes plan around them"); decor is flat and lowest-contrast with no volume
    /// ("sim-inert — never blocks a body").
    static func drawObstacles(_ obstacles: [Obstacle], projection: CanvasProjection, into context: inout GraphicsContext) {
        for obstacle in obstacles {
            let origin = projection.point(obstacle.origin)
            let rect = CGRect(
                x: origin.x, y: origin.y,
                width: projection.length(obstacle.size.x), height: projection.length(obstacle.size.y)
            )
            let radius = min(4, rect.width / 4)
            let shape = Path(roundedRect: rect, cornerRadius: radius)

            switch obstacle.simClass {
            case .relocatable:
                context.fill(shape, with: .color(.egPropFill))
                context.stroke(shape, with: .color(.egPropEdge), lineWidth: 1)
                drawLitTopEdge(rect, radius: radius, into: &context)
                drawGripDots(rect, into: &context)
            case .structural:
                context.fill(shape, with: .color(.egPropStructural))
                context.stroke(shape, with: .color(.egPropStructuralOutline), lineWidth: 1.75)
                drawAnchorNotch(rect, into: &context)
            case .decor:
                context.fill(shape, with: .color(.egPropFill.opacity(0.3)))
                context.stroke(shape, with: .color(.egPropEdge.opacity(0.55)), lineWidth: 1)
            }

            drawPropGlyph(obstacle, in: rect, into: &context)
        }
    }

    /// The prop's own icon, stamped into the middle of its footprint, so each type reads distinctly on
    /// the canvas (a Bar's glass vs. a Stage's mic) instead of every box looking the same. The plain
    /// freeform `Object` carries no glyph — it stays the generic box it always was.
    private static func drawPropGlyph(_ obstacle: Obstacle, in rect: CGRect, into context: inout GraphicsContext) {
        guard obstacle.kind != EditorProp.object.kind,
              let symbol = EditorProp.byKind[obstacle.kind]?.symbol else { return }
        let side = min(rect.width, rect.height) * 0.62
        guard side >= 11 else { return } // too small to read — the class chrome alone carries it
        let opacity: Double = obstacle.simClass == .decor ? 0.65 : 0.92
        let glyph = Text(Image(systemName: symbol))
            .font(.system(size: side, weight: .medium))
            .foregroundColor(.egCanvasText.opacity(opacity))
        context.draw(glyph, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }

    /// A lighter hairline along a relocatable prop's top edge — the "lit" face that gives it volume.
    private static func drawLitTopEdge(_ rect: CGRect, radius: CGFloat, into context: inout GraphicsContext) {
        guard rect.width > radius * 2 + 2 else { return }
        var top = Path()
        top.move(to: CGPoint(x: rect.minX + radius, y: rect.minY + 1))
        top.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY + 1))
        context.stroke(top, with: .color(.egAgentCalm.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }

    /// Four small grip-dots inset from the corners — the "you may move this" affordance.
    private static func drawGripDots(_ rect: CGRect, into context: inout GraphicsContext) {
        guard rect.width > 12, rect.height > 12 else { return }
        let inset: CGFloat = 3.5
        let dot: CGFloat = 1.6
        for point in [
            CGPoint(x: rect.minX + inset, y: rect.minY + inset), CGPoint(x: rect.maxX - inset, y: rect.minY + inset),
            CGPoint(x: rect.minX + inset, y: rect.maxY - inset), CGPoint(x: rect.maxX - inset, y: rect.maxY - inset)
        ] {
            let dotRect = CGRect(x: point.x - dot / 2, y: point.y - dot / 2, width: dot, height: dot)
            context.fill(Circle().path(in: dotRect), with: .color(.egPropEdge))
        }
    }

    /// A small cyan square at the top-left corner — the structural prop's fixed anchor mark.
    private static func drawAnchorNotch(_ rect: CGRect, into context: inout GraphicsContext) {
        let side = min(6, min(rect.width, rect.height) * 0.35)
        guard side >= 2 else { return }
        let notch = CGRect(x: rect.minX + 1.5, y: rect.minY + 1.5, width: side, height: side)
        context.fill(Path(roundedRect: notch, cornerRadius: 1), with: .color(.egCyan))
    }

    /// Exit spans — the cyan doorways agents flow toward. `labelled` adds the clear-width callout the
    /// editor shows against each exit (the live canvas leaves it off so agents don't fight the label).
    static func drawExits(
        _ exits: [Exit], projection: CanvasProjection, labelled: Bool = false, into context: inout GraphicsContext
    ) {
        for exit in exits {
            var path = Path()
            path.move(to: projection.point(exit.a))
            path.addLine(to: projection.point(exit.b))
            context.stroke(path, with: .color(.egCyan), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            guard labelled else { continue }
            let mid = projection.point(exit.center)
            context.draw(
                Text(String(format: "%.1f m", exit.width))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.egCyan),
                at: CGPoint(x: mid.x, y: mid.y - 12), anchor: .center
            )
        }
    }
}
