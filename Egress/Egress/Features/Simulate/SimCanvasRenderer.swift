import EgressEngine
import SwiftUI

// MARK: - CanvasProjection

/// Maps venue world-space (metres; y grows toward the exit wall) onto the Canvas (points; y
/// grows downward — so the mapping is direct, no flip). Uniform scale preserves the room's true
/// aspect ratio and centres it with an inset. S2's pan/zoom camera composes on top of this.
struct CanvasProjection {
    let scale: CGFloat // points per metre
    private let origin: CGPoint // screen point of world (0, 0)

    init(worldWidth: Double, worldHeight: Double, viewSize: CGSize, inset: CGFloat = 20) {
        let usableWidth = max(1, viewSize.width - inset * 2)
        let usableHeight = max(1, viewSize.height - inset * 2)
        scale = CGFloat(min(usableWidth / worldWidth, usableHeight / worldHeight))
        let drawnWidth = CGFloat(worldWidth) * scale
        let drawnHeight = CGFloat(worldHeight) * scale
        origin = CGPoint(x: (viewSize.width - drawnWidth) / 2, y: (viewSize.height - drawnHeight) / 2)
    }

    /// World point (metres) → screen point (points).
    func point(_ world: Vec2) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(world.x) * scale, y: origin.y + CGFloat(world.y) * scale)
    }

    /// Screen point (points) → world point (metres). Inverse of `point(_:)` — the editor maps a
    /// finger's location back into venue metres to place walls, exits and obstacles.
    func world(_ screen: CGPoint) -> Vec2 {
        Vec2(Double((screen.x - origin.x) / scale), Double((screen.y - origin.y) / scale))
    }

    /// A length in metres → points.
    func length(_ metres: Double) -> CGFloat {
        CGFloat(metres) * scale
    }
}

// MARK: - SimulationRenderer

/// Pure drawing of one `SimulationSnapshot`. No state, no timing — same snapshot ⇒ same frame.
/// Layer order is the design spec's stack, with the venue's built geometry (walls + obstacles)
/// sitting on the grid beneath the live layers: grid → walls → obstacles → density → hazards →
/// exits → agents. Grid, walls, obstacles and exits are shared with the editor via `VenueScenery`.
enum SimulationRenderer {
    static func draw(
        _ snapshot: SimulationSnapshot,
        venue: VenueModel,
        projection: CanvasProjection,
        patternFills: Bool = true,
        into context: inout GraphicsContext
    ) {
        VenueScenery.drawGrid(venue: venue, projection: projection, into: &context)
        VenueScenery.drawObstacles(venue.obstacles, projection: projection, into: &context)
        VenueScenery.drawWalls(venue.walls, projection: projection, into: &context)
        drawDensity(
            snapshot.density,
            cellSize: venue.geometry.cellSize,
            projection: projection,
            patternFills: patternFills,
            into: &context
        )
        drawHazards(snapshot.hazards, cellSize: venue.geometry.cellSize, projection: projection, into: &context)
        VenueScenery.drawExits(venue.exits, projection: projection, into: &context)
        drawAgents(snapshot.agents, projection: projection, into: &context)
    }

    /// Per-cell density bands (persons·m⁻²). Comfortable renders nothing — only crowding shows. When
    /// `patternFills` is on (§5.6 colour-vision pass) each band also carries a texture — sparse dots for
    /// congestion, a diagonal hatch for at-risk, a cross-hatch for a crush — so the bands are legible
    /// without relying on hue.
    private static func drawDensity(
        _ density: DensityGrid,
        cellSize: Double,
        projection: CanvasProjection,
        patternFills: Bool,
        into context: inout GraphicsContext
    ) {
        let side = projection.length(cellSize) + 0.5 // +0.5 hides seams between cells
        var congested = Path()
        var atRisk = Path()
        var crush = Path()
        for index in 0 ..< density.size.count {
            let coord = density.size.coord(atIndex: index)
            let value = density.value(at: coord)
            guard value >= 2 else { continue }
            let topLeft = projection.point(Vec2(Double(coord.x) * cellSize, Double(coord.y) * cellSize))
            let rect = CGRect(x: topLeft.x, y: topLeft.y, width: side, height: side)
            if value >= 6 {
                crush.addRect(rect)
            } else if value >= 4 {
                atRisk.addRect(rect)
            } else {
                congested.addRect(rect)
            }
        }
        context.fill(congested, with: .color(.egDensityCongested))
        context.fill(atRisk, with: .color(.egDensityAtRisk))
        context.fill(crush, with: .color(.egDensityCrush))
        guard patternFills else { return }
        // Texture overlays, clipped to each band's cells, drawn brightest-band-last so a crush reads on
        // top. The stroke colour is a lightened tint of the band so the pattern stays visible on its fill.
        strokePattern(
            .dots,
            over: congested,
            spacing: projection.length(0.5),
            colour: .egDensityCongestedPattern,
            into: &context
        )
        strokePattern(
            .diagonal,
            over: atRisk,
            spacing: projection.length(0.45),
            colour: .egDensityAtRiskPattern,
            into: &context
        )
        strokePattern(
            .cross,
            over: crush,
            spacing: projection.length(0.4),
            colour: .egDensityCrushPattern,
            into: &context
        )
    }

    /// The three colour-blind textures. Each is a set of hairlines (or dots) generated across the band's
    /// bounding box, then clipped to the band's own cells so only crowded floor is textured.
    private enum DensityPattern { case dots, diagonal, cross }

    private static func strokePattern(
        _ pattern: DensityPattern,
        over band: Path,
        spacing: CGFloat,
        colour: Color,
        into context: inout GraphicsContext
    ) {
        let bounds = band.boundingRect
        guard !bounds.isEmpty, spacing > 1 else { return }
        context.drawLayer { layer in
            layer.clip(to: band)
            switch pattern {
            case .dots:
                let r = max(0.6, spacing * 0.12)
                var y = bounds.minY
                while y <= bounds.maxY {
                    var x = bounds.minX
                    while x <= bounds.maxX {
                        layer.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                            with: .color(colour)
                        )
                        x += spacing
                    }
                    y += spacing
                }
            case .diagonal:
                layer.stroke(
                    diagonalLines(in: bounds, spacing: spacing, rising: true),
                    with: .color(colour),
                    lineWidth: 1
                )
            case .cross:
                layer.stroke(
                    diagonalLines(in: bounds, spacing: spacing, rising: true),
                    with: .color(colour),
                    lineWidth: 1
                )
                layer.stroke(
                    diagonalLines(in: bounds, spacing: spacing, rising: false),
                    with: .color(colour),
                    lineWidth: 1
                )
            }
        }
    }

    /// A field of parallel 45° lines covering `bounds`, rising (↗) or falling (↘). Offsetting the line
    /// origin from `-height` to `+width` guarantees the whole box is swept regardless of aspect.
    private static func diagonalLines(in bounds: CGRect, spacing: CGFloat, rising: Bool) -> Path {
        var path = Path()
        var offset = -bounds.height
        while offset <= bounds.width {
            let x = bounds.minX + offset
            if rising {
                path.move(to: CGPoint(x: x, y: bounds.maxY))
                path.addLine(to: CGPoint(x: x + bounds.height, y: bounds.minY))
            } else {
                path.move(to: CGPoint(x: x, y: bounds.minY))
                path.addLine(to: CGPoint(x: x + bounds.height, y: bounds.maxY))
            }
            offset += spacing
        }
        return path
    }

    private static func drawHazards(
        _ hazards: HazardSnapshot, cellSize: Double, projection: CanvasProjection, into context: inout GraphicsContext
    ) {
        let side = projection.length(cellSize) + 0.5
        for (coord, opacity) in hazards.smoke where opacity > 0.01 {
            let topLeft = projection.point(Vec2(Double(coord.x) * cellSize, Double(coord.y) * cellSize))
            let rect = CGRect(x: topLeft.x, y: topLeft.y, width: side, height: side)
            context.fill(Path(rect), with: .color(.egHazardSmoke.opacity(min(0.8, opacity))))
        }
        for (coord, intensity) in hazards.fire where intensity > 0.01 {
            let topLeft = projection.point(Vec2(Double(coord.x) * cellSize, Double(coord.y) * cellSize))
            let rect = CGRect(x: topLeft.x, y: topLeft.y, width: side, height: side)
            let colour = intensity >= 0.66 ? Color.egHazardFireCore : Color.egHazardFire
            context.fill(Path(rect), with: .color(colour))
        }
    }

    private static func drawAgents(_ agents: [AgentRender], projection: CanvasProjection, into context: inout GraphicsContext) {
        let radius = max(2, projection.length(SafetyStandards.bodyRadius))
        for agent in agents where agent.status.isActive {
            let centre = projection.point(agent.position)
            let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(colour(for: agent)))
        }
    }

    /// Staff read as violet regardless of mood; everyone else is tinted by emotional state.
    private static func colour(for agent: AgentRender) -> Color {
        if agent.mobility == .staff {
            return .egAgentStaff
        }
        switch agent.emotion {
        case .calm: return .egAgentCalm
        case .uneasy: return .egAgentUneasy
        case .panicked: return .egAgentPanicked
        }
    }
}
