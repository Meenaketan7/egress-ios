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

    /// The free-form editor's dot grid (design's ReactFlow-style board): the 0.25 m grid tiled across
    /// the *visible* world rect rather than a fixed room, so it fills the canvas at any pan/zoom. Minor
    /// dots drop out when the camera is too far out for them to read; the whole grid is skipped when even
    /// the 1 m majors would collide, keeping deep zoom-outs clean and cheap.
    static func drawEditorGrid(projection: CanvasProjection, viewSize: CGSize, into context: inout GraphicsContext) {
        let cell = SafetyStandards.cellSize
        let cellPts = projection.length(cell)
        guard cellPts > 0, cellPts * 4 >= 6 else { return } // too far out — the grid would just be mud
        let topLeft = projection.world(.zero)
        let bottomRight = projection.world(CGPoint(x: viewSize.width, y: viewSize.height))
        let minX = (topLeft.x / cell).rounded(.down) * cell
        let minY = (topLeft.y / cell).rounded(.down) * cell
        let minorVisible = cellPts >= 5
        let dot: CGFloat = 1.5
        var minor = Path()
        var major = Path()
        var row = Int((minY / cell).rounded())
        var gridY = minY
        while gridY <= bottomRight.y {
            var col = Int((minX / cell).rounded())
            var gridX = minX
            while gridX <= bottomRight.x {
                let isMajor = col % 4 == 0 && row % 4 == 0
                if isMajor || minorVisible {
                    let centre = projection.point(Vec2(gridX, gridY))
                    let rect = CGRect(x: centre.x - dot / 2, y: centre.y - dot / 2, width: dot, height: dot)
                    if isMajor {
                        major.addEllipse(in: rect)
                    } else {
                        minor.addEllipse(in: rect)
                    }
                }
                gridX += cell
                col += 1
            }
            gridY += cell
            row += 1
        }
        context.fill(minor, with: .color(.egCanvasGrid))
        context.fill(major, with: .color(.egCanvasGridMajor))
    }

    /// Dim a set of out-of-room cells — the exterior of the walls' enclosed room (`RoomEnclosure`) — so a
    /// non-rectangular shape (L, T, angled) reads at a glance in both the editor and the live run. Cells
    /// are in the grid frame; `origin` is the world-metre position of cell (0,0): the editor offsets by
    /// its content bounds, the normalised sim venue uses zero. Empty set ⇒ nothing drawn (room = grid).
    static func drawExteriorShade(
        _ cells: Set<GridCoord>, origin: Vec2, cellSize: Double, projection: CanvasProjection, into context: inout GraphicsContext
    ) {
        guard !cells.isEmpty else { return }
        let side = projection.length(cellSize) + 0.5 // +0.5 closes seams between cells
        var path = Path()
        for coord in cells {
            let world = Vec2(origin.x + Double(coord.x) * cellSize, origin.y + Double(coord.y) * cellSize)
            let point = projection.point(world)
            path.addRect(CGRect(x: point.x, y: point.y, width: side, height: side))
        }
        context.fill(path, with: .color(.black.opacity(0.34)))
    }

    /// Standing-water flood zones — a translucent teal fill with a light wave hatch, drawn beneath the
    /// obstacles. Static and impassable: the crowd routes around it exactly as it would a wall, so it
    /// reads as a distinct *no-go* hazard rather than furniture (design's HAZARDS · Water).
    static func drawWater(_ zones: [WaterZone], projection: CanvasProjection, into context: inout GraphicsContext) {
        for zone in zones {
            let origin = projection.point(zone.origin)
            let rect = CGRect(
                x: origin.x, y: origin.y,
                width: projection.length(zone.size.x), height: projection.length(zone.size.y)
            )
            let radius = min(4, rect.width / 4)
            let shape = Path(roundedRect: rect, cornerRadius: radius)
            context.fill(shape, with: .color(.egHazardFlood.opacity(0.5)))
            context.stroke(shape, with: .color(.egHazardFlood), lineWidth: 1.5)
            drawWaveHatch(rect, into: &context)
        }
    }

    /// A few horizontal ripples clipped to a flood zone — the "≈" that sells the water read.
    private static func drawWaveHatch(_ rect: CGRect, into context: inout GraphicsContext) {
        guard rect.width > 10, rect.height > 8 else { return }
        let amp = min(2.5, rect.height * 0.06)
        let wavelength = max(8, rect.width / 6)
        let spacing = max(6, rect.height / 4)
        context.drawLayer { layer in
            layer.clip(to: Path(rect))
            var y = rect.minY + spacing
            while y < rect.maxY {
                var path = Path()
                path.move(to: CGPoint(x: rect.minX, y: y))
                var x = rect.minX
                while x < rect.maxX {
                    let mid = x + wavelength / 2
                    path.addQuadCurve(to: CGPoint(x: min(mid, rect.maxX), y: y), control: CGPoint(x: x + wavelength / 4, y: y - amp))
                    let end = mid + wavelength / 2
                    path.addQuadCurve(to: CGPoint(x: min(end, rect.maxX), y: y), control: CGPoint(x: mid + wavelength / 4, y: y + amp))
                    x = end
                }
                layer.stroke(path, with: .color(.egCanvasText.opacity(0.28)), lineWidth: 1)
                y += spacing
            }
        }
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
