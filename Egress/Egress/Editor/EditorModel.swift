import EgressEngine
import Foundation
import Observation
import SwiftUI

// MARK: - EditorTool

/// The active drawing tool. Wall/exit are drawn by dragging a line; obstacle by dragging a box;
/// erase removes the nearest element under a tap.
enum EditorTool: String, CaseIterable, Identifiable {
    case wall, exit, obstacle, erase

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wall: "Wall"
        case .exit: "Exit"
        case .obstacle: "Object"
        case .erase: "Erase"
        }
    }

    var symbol: String {
        switch self {
        case .wall: "line.diagonal"
        case .exit: "arrow.up.right.square"
        case .obstacle: "square.dashed"
        case .erase: "minus.circle"
        }
    }

    /// The one-line instruction shown beneath the canvas for the selected tool.
    var hint: String {
        switch self {
        case .wall: "Drag to draw an impassable wall."
        case .exit: "Drag along an edge to place a doorway."
        case .obstacle: "Drag a box to drop furniture people route around."
        case .erase: "Tap a wall, exit, or object to remove it."
        }
    }

    var tint: Color {
        switch self {
        case .wall: .egPropStructuralOutline
        case .exit: .egCyan
        case .obstacle: .egPropEdge
        case .erase: .egVerdictFail
        }
    }
}

// MARK: - EditPlacement

/// The outcome of committing an editor drag, so the view can pick the right §5.5 haptic without the
/// model reaching for UIKit: something was placed, something was erased, a real attempt fell short, or
/// the gesture was just a tap and nothing happened.
enum EditPlacement { case placed, erased, rejected, none }

// MARK: - EditorDraft

/// The element currently being dragged out, in world metres (already snapped). The canvas paints
/// this as a translucent ghost so the user sees the wall/exit/box before they lift their finger.
struct EditorDraft: Equatable {
    var tool: EditorTool
    var start: Vec2
    var current: Vec2
}

// MARK: - EditorModel

/// The mutable state behind the parametric editor: room size, the walls/exits/obstacles the user
/// draws, the crowd size, and the active tool. It derives the immutable `VenueModel` +
/// `SimulationConfig` the simulator runs, and validates — using the engine's own exit seeding — that
/// the authored floor actually drains before the user can hit Simulate.
@MainActor
@Observable
final class EditorModel {
    var name: String
    var type: VenueType
    /// Room extent in metres. Snapped to 0.5 m by the steppers, so the derived grid is always exact.
    var widthMetres: Double
    var heightMetres: Double
    /// Occupancy — becomes `SimulationConfig.agentCount`.
    var crowd: Int
    var tool: EditorTool = .wall

    private(set) var walls: [Wall] = []
    private(set) var exits: [Exit] = []
    private(set) var obstacles: [Obstacle] = []
    /// The in-progress drag, or `nil` between gestures.
    private(set) var draft: EditorDraft?

    /// Monotonic id source for exits and obstacles (the engine keys RALLY fixes off these ids).
    private var nextID = 1

    static let minCrowd = 5
    static let maxCrowd = 400
    static let minRoom = 4.0
    static let maxRoom = 30.0

    private let minWallLength = 0.5
    private let minExitWidth = 0.5
    private let minObstacleSide = 0.5
    private let eraseRadius = 0.6

    /// A fresh draft: an 11 × 8 m nightclub with one 1.0 m exit centred on the far edge, so the venue
    /// is valid from the first frame and the user can simulate immediately, then refine.
    init(
        name: String = "",
        type: VenueType = .nightclub,
        widthMetres: Double = 11,
        heightMetres: Double = 8,
        crowd: Int = 120
    ) {
        self.name = name
        self.type = type
        self.widthMetres = widthMetres
        self.heightMetres = heightMetres
        self.crowd = crowd
        let cx = widthMetres / 2
        exits = [Exit(id: allocID(), a: Vec2(cx - 0.5, heightMetres), b: Vec2(cx + 0.5, heightMetres))]
    }

    /// Seed the editor from a furnished preset — its room size, type, name, crowd, and full
    /// prop/exit/wall layout — so the user lands on a real, simulable venue they can tweak or run
    /// straight away rather than an empty box. `nextID` is advanced past the preset's element ids so
    /// further edits never collide with them.
    convenience init(preset: VenuePreset) {
        self.init(
            name: preset.venue.name,
            type: preset.venue.type,
            widthMetres: preset.widthMetres,
            heightMetres: preset.heightMetres,
            crowd: preset.crowd
        )
        walls = preset.venue.walls
        exits = preset.venue.exits
        obstacles = preset.venue.obstacles
        nextID = ((exits.map(\.id) + obstacles.map(\.id)).max() ?? 0) + 1
    }

    // MARK: Derived venue

    private var cellSize: Double { SafetyStandards.cellSize }
    var worldWidth: Double { geometry.worldWidth }
    var worldHeight: Double { geometry.worldHeight }

    /// The grid the room's metre extent maps to (0.25 m cells).
    var geometry: GridGeometry {
        let w = max(1, Int((widthMetres / cellSize).rounded()))
        let h = max(1, Int((heightMetres / cellSize).rounded()))
        return GridGeometry(size: GridSize(width: w, height: h))
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? type.displayName : trimmed
    }

    /// The immutable venue the simulator runs — a snapshot of the current draft.
    var venue: VenueModel {
        VenueModel(
            id: 0, name: displayName, type: type, geometry: geometry,
            walls: walls, exits: exits, obstacles: obstacles
        )
    }

    /// Reproducible config — a fixed seed so re-running the same draft replays the same crowd.
    var config: SimulationConfig {
        SimulationConfig(agentCount: crowd, maxValidatedAgents: 300, seed: 42)
    }

    // MARK: Editing

    /// Live-track the drag as a ghost (erase shows none — it acts on release).
    func dragChanged(from start: Vec2, to current: Vec2) {
        guard tool != .erase else { return }
        draft = EditorDraft(tool: tool, start: snap(start), current: snap(current))
    }

    /// Commit the finished drag as a new element, dropping degenerate (too-small) gestures. Returns the
    /// outcome so the canvas can fire the matching placement haptic (§5.5): a real drag that fell short
    /// of the minimum is `.rejected`, while a plain tap that drew nothing is `.none` (no buzz on a tap).
    @discardableResult
    func dragEnded(from start: Vec2, to current: Vec2) -> EditPlacement {
        defer { draft = nil }
        let a = snap(start)
        let b = snap(current)
        let dragged = a.distance(to: b)
        switch tool {
        case .wall:
            if dragged >= minWallLength { walls.append(Wall(a: a, b: b)); return .placed }
            return dragged > 0 ? .rejected : .none
        case .exit:
            if dragged >= minExitWidth { exits.append(Exit(id: allocID(), a: a, b: b)); return .placed }
            return dragged > 0 ? .rejected : .none
        case .obstacle:
            let (origin, size) = box(a, b)
            if size.x >= minObstacleSide, size.y >= minObstacleSide {
                obstacles.append(Obstacle(id: allocID(), origin: origin, size: size, isRelocatable: true))
                return .placed
            }
            return (size.x > 0 || size.y > 0) ? .rejected : .none
        case .erase:
            return erase(near: b) ? .erased : .none
        }
    }

    /// Remove every drawn element (room size, type and crowd are kept).
    func clearElements() {
        walls.removeAll()
        exits.removeAll()
        obstacles.removeAll()
        draft = nil
    }

    /// Pull any element endpoints back inside the room after a resize so nothing floats off-canvas.
    /// Call this when width/height changes. Degenerate leftovers are dropped.
    func clampToBounds() {
        let w = worldWidth
        let h = worldHeight
        func c(_ v: Vec2) -> Vec2 { Vec2(clampD(v.x, 0, w), clampD(v.y, 0, h)) }
        walls = walls.map { Wall(a: c($0.a), b: c($0.b)) }.filter { $0.length >= minWallLength }
        exits = exits.map { Exit(id: $0.id, a: c($0.a), b: c($0.b)) }.filter { $0.width >= minExitWidth }
        obstacles = obstacles.compactMap { o in
            let origin = c(o.origin)
            let far = c(o.origin + o.size)
            let size = Vec2(far.x - origin.x, far.y - origin.y)
            guard size.x >= minObstacleSide, size.y >= minObstacleSide else { return nil }
            return Obstacle(id: o.id, origin: origin, size: size, isRelocatable: o.isRelocatable)
        }
    }

    // MARK: Validation

    /// People per net m² of floor — the *average* loading, not the sim's local peak. Bands are a
    /// coarse "is this room over-packed before anyone even moves" heuristic.
    var crowdDensity: Double {
        let area = venue.netFloorArea
        return area > 0 ? Double(crowd) / area : 0
    }

    var crowdLoadLabel: String {
        switch crowdDensity {
        case ..<1.0: "Roomy"
        case ..<2.0: "Comfortable"
        case ..<3.5: "Busy"
        default: "Packed"
        }
    }

    var crowdLoadTint: Color {
        switch crowdDensity {
        case ..<2.0: .egVerdictPass
        case ..<3.5: .egVerdictWarn
        default: .egVerdictFail
        }
    }

    /// Fraction of open floor that can actually reach an exit — computed with the engine's own exit
    /// seeding and flood, so a walled-off exit or a sealed pocket shows up here exactly as the run
    /// would see it. 1.0 means every free cell drains; a low value means people would be trapped.
    var reachableFloorFraction: Double {
        let model = venue
        let size = model.geometry.size
        guard !size.isEmpty, !model.exits.isEmpty else { return 0 }
        let blocked = BlockedCells.of(model)
        let seeds = Simulation.exitCells(model.exits, in: model.geometry)
        let field = FlowField(size: size, blocked: blocked, exits: seeds)
        var free = 0
        var reachable = 0
        for index in 0 ..< size.count {
            let coord = size.coord(atIndex: index)
            if blocked.contains(coord) { continue }
            free += 1
            if field.isReachable(coord) { reachable += 1 }
        }
        return free > 0 ? Double(reachable) / Double(free) : 0
    }

    /// Simulable when there's a real grid, at least one exit, and most of the floor can drain.
    var isSimulable: Bool { venue.isValid && reachableFloorFraction >= 0.5 }

    /// A human reason the draft can't run yet, or `nil` when it's good to go.
    var blockingIssue: String? {
        if exits.isEmpty { return "Add at least one exit." }
        let reachable = reachableFloorFraction
        if reachable < 0.5 {
            return "Only \(Int(reachable * 100))% of the floor can reach an exit — clear a path or add a door."
        }
        return nil
    }

    // MARK: Geometry helpers

    private func allocID() -> Int {
        defer { nextID += 1 }
        return nextID
    }

    /// Snap a world point to the 0.25 m grid and clamp it inside the room.
    private func snap(_ p: Vec2) -> Vec2 {
        Vec2(
            clampD((p.x / cellSize).rounded() * cellSize, 0, worldWidth),
            clampD((p.y / cellSize).rounded() * cellSize, 0, worldHeight)
        )
    }

    private func clampD(_ v: Double, _ lo: Double, _ hi: Double) -> Double { min(max(v, lo), hi) }

    /// Lower corner + positive size of the box spanned by two dragged corners.
    private func box(_ a: Vec2, _ b: Vec2) -> (Vec2, Vec2) {
        (Vec2(min(a.x, b.x), min(a.y, b.y)), Vec2(abs(b.x - a.x), abs(b.y - a.y)))
    }

    /// Remove the single closest element within the erase radius of `p`. Returns whether anything was
    /// actually removed, so a missed erase tap stays silent.
    @discardableResult
    private func erase(near p: Vec2) -> Bool {
        enum Kind { case obstacle, exit, wall }
        var best: (kind: Kind, index: Int, dist: Double)?
        func consider(_ kind: Kind, _ index: Int, _ dist: Double) {
            guard dist <= eraseRadius else { return }
            if best == nil || dist < best!.dist { best = (kind, index, dist) }
        }
        for (i, o) in obstacles.enumerated() { consider(.obstacle, i, distanceToBox(p, origin: o.origin, size: o.size)) }
        for (i, e) in exits.enumerated() { consider(.exit, i, distanceToSegment(p, e.a, e.b)) }
        for (i, w) in walls.enumerated() { consider(.wall, i, distanceToSegment(p, w.a, w.b)) }
        guard let hit = best else { return false }
        switch hit.kind {
        case .obstacle: obstacles.remove(at: hit.index)
        case .exit: exits.remove(at: hit.index)
        case .wall: walls.remove(at: hit.index)
        }
        return true
    }

    private func distanceToSegment(_ p: Vec2, _ a: Vec2, _ b: Vec2) -> Double {
        let ab = b - a
        let len2 = ab.lengthSquared
        guard len2 > 1e-12 else { return p.distance(to: a) }
        let t = min(max((p - a).dot(ab) / len2, 0), 1)
        return p.distance(to: a + ab * t)
    }

    private func distanceToBox(_ p: Vec2, origin: Vec2, size: Vec2) -> Double {
        let dx = max(max(origin.x - p.x, p.x - (origin.x + size.x)), 0)
        let dy = max(max(origin.y - p.y, p.y - (origin.y + size.y)), 0)
        return Vec2(dx, dy).length
    }
}
