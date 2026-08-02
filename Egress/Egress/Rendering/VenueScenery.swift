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
        context.stroke(path, with: .color(.egPropStructuralOutline),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    /// Obstacle boxes — furniture (relocatable) reads lighter than structure (fixed), matching the
    /// engine's `isRelocatable` split even though both block movement identically.
    static func drawObstacles(_ obstacles: [Obstacle], projection: CanvasProjection, into context: inout GraphicsContext) {
        for obstacle in obstacles {
            let origin = projection.point(obstacle.origin)
            let rect = CGRect(
                x: origin.x, y: origin.y,
                width: projection.length(obstacle.size.x), height: projection.length(obstacle.size.y)
            )
            let shape = Path(roundedRect: rect, cornerRadius: min(4, rect.width / 4))
            let fill: Color = obstacle.isRelocatable ? .egPropFill : .egPropStructural
            let edge: Color = obstacle.isRelocatable ? .egPropEdge : .egPropStructuralOutline
            context.fill(shape, with: .color(fill))
            context.stroke(shape, with: .color(edge), lineWidth: 1)
        }
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
