import EgressEngine
import Foundation
import Observation
import SwiftUI

// MARK: - EditorToolGroup

/// A toolbar grouping, mirroring the design's CONSTRUCTION · PROPS · HAZARDS layout.
enum EditorToolGroup: String, CaseIterable, Identifiable {
    case build, props, hazards
    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .build: "Build"
        case .props: "Props"
        case .hazards: "Hazards"
        }
    }
}

// MARK: - EditorTool

/// The active tool. Select taps to pick an element (then drag or the floating pad moves it); wall/exit
/// are drawn by dragging a line; obstacle by dragging a box; erase removes the nearest element under a
/// tap; fire drops an ignition point with a tap.
enum EditorTool: String, CaseIterable, Identifiable {
    case select, wall, exit, erase, obstacle, fire

    var id: String {
        rawValue
    }

    var group: EditorToolGroup {
        switch self {
        case .select, .wall, .exit, .erase: .build
        case .obstacle: .props
        case .fire: .hazards
        }
    }

    var label: String {
        switch self {
        case .select: "Select"
        case .wall: "Wall"
        case .exit: "Exit"
        case .obstacle: "Object"
        case .erase: "Erase"
        case .fire: "Fire"
        }
    }

    /// The imperative shown in the tool-state pill above the canvas ("DRAW WALL").
    var actionLabel: String {
        switch self {
        case .select: "Select"
        case .wall: "Draw wall"
        case .exit: "Place exit"
        case .obstacle: "Place object"
        case .erase: "Erase"
        case .fire: "Drop fire"
        }
    }

    var symbol: String {
        switch self {
        case .select: "hand.point.up.left.fill"
        case .wall: "line.diagonal"
        case .exit: "arrow.up.right.square"
        case .obstacle: "square.dashed"
        case .erase: "minus.circle"
        case .fire: "flame.fill"
        }
    }

    /// The one-line instruction shown beneath the canvas for the selected tool.
    var hint: String {
        switch self {
        case .select: "Tap an item to select it, then drag or use the arrows to move it."
        case .wall: "Drag to draw an impassable wall."
        case .exit: "Drag along an edge to place a doorway."
        case .obstacle: "Drag a box to drop furniture people route around."
        case .erase: "Tap a wall, exit, object, or fire to remove it."
        case .fire: "Tap to drop a fire ignition point the crowd must avoid."
        }
    }

    var tint: Color {
        switch self {
        case .select: .egCyan
        case .wall: .egDataGreen
        case .exit: .egCyan
        case .obstacle: .egPropEdge
        case .erase: .egVerdictFail
        case .fire: .egHazardFire
        }
    }
}

// MARK: - EditorSelection

/// The element the Select tool currently has picked, so the floating pad can move/configure it.
enum EditorSelection: Equatable {
    case obstacle(Int)
    case exit(Int)
    case ignition(Int)
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
    var tool: EditorTool = .select {
        didSet {
            if tool != .select {
                selection = nil
            }
        } // leaving Select drops the picked element
    }

    /// The prop the Props tool will place. Defaults to the freeform `.object` box, so the obstacle
    /// tool behaves exactly as before until the user picks a named prop from the library sheet. Every
    /// prop places with the same drag-to-size gesture; only its identity and simulation class differ.
    var activeProp: EditorProp = .object

    private(set) var walls: [Wall] = []
    private(set) var exits: [Exit] = []
    private(set) var obstacles: [Obstacle] = []
    /// Fire ignition points in world metres — fed straight into `SimulationConfig.ignition` (§2.7).
    private(set) var ignitions: [Vec2] = []
    /// The element the Select tool has picked (drives the floating move/config pad), or `nil`.
    private(set) var selection: EditorSelection?
    /// The snapshot of the element being dragged, captured at drag-start so moves are absolute.
    private var moveAnchor: MoveAnchor?
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

    private var cellSize: Double {
        SafetyStandards.cellSize
    }

    var worldWidth: Double {
        geometry.worldWidth
    }

    var worldHeight: Double {
        geometry.worldHeight
    }

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
            id: 0,
            name: displayName,
            type: type,
            geometry: geometry,
            walls: walls,
            exits: exits,
            obstacles: obstacles
        )
    }

    /// Reproducible config — a fixed seed so re-running the same draft replays the same crowd, plus any
    /// editor-placed fire so the authored hazard actually burns in the run.
    var config: SimulationConfig {
        SimulationConfig(agentCount: crowd, maxValidatedAgents: 300, seed: 42, ignition: ignitions)
    }

    // MARK: Editing

    /// Live-track the drag as a ghost. Select, erase and fire act differently (move / tap), so no ghost.
    func dragChanged(from start: Vec2, to current: Vec2) {
        guard tool != .select, tool != .erase, tool != .fire else { return }
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
        case .select:
            return .none // Select is driven by select()/beginMove()/updateMove(), not here.
        case .wall:
            if dragged >= minWallLength {
                walls.append(Wall(a: a, b: b))
                return .placed
            }
            return dragged > 0 ? .rejected : .none
        case .exit:
            if dragged >= minExitWidth {
                exits.append(Exit(id: allocID(), a: a, b: b))
                return .placed
            }
            return dragged > 0 ? .rejected : .none
        case .obstacle:
            let (origin, size) = box(a, b)
            if size.x >= minObstacleSide, size.y >= minObstacleSide {
                obstacles.append(Obstacle(
                    id: allocID(), origin: origin, size: size,
                    simClass: activeProp.simClass, kind: activeProp.kind
                ))
                return .placed
            }
            return (size.x > 0 || size.y > 0) ? .rejected : .none
        case .erase:
            return erase(near: b) ? .erased : .none
        case .fire:
            // A tap drops one ignition point; a stray double-tap on the same cell is ignored.
            let p = b
            if !ignitions.contains(where: { $0.distance(to: p) < cellSize }) {
                ignitions.append(p)
                return .placed
            }
            return .none
        }
    }

    /// Remove every drawn element and hazard (room size, type and crowd are kept).
    func clearElements() {
        walls.removeAll()
        exits.removeAll()
        obstacles.removeAll()
        ignitions.removeAll()
        selection = nil
        draft = nil
    }

    /// Remove every placed fire ignition point.
    func clearIgnitions() {
        ignitions.removeAll()
        if case .ignition = selection {
            selection = nil
        }
    }

    // MARK: Select & move (§3.5 direct manipulation)

    private let selectRadius = 0.9
    private enum MoveAnchor {
        case obstacle(id: Int, origin: Vec2)
        case exit(id: Int, a: Vec2, b: Vec2)
        case ignition(index: Int, point: Vec2)
    }

    /// True while a selected element is being dragged.
    var isMoving: Bool {
        moveAnchor != nil
    }

    /// Pick the nearest element to `p` (or clear the selection if the tap missed everything).
    func select(near p: Vec2) {
        selection = nearestSelectable(near: p)
    }

    func clearSelection() {
        selection = nil
        moveAnchor = nil
    }

    /// Begin a drag-move if the drag started on a movable element; also selects it.
    func beginMove(near p: Vec2) {
        guard let hit = nearestSelectable(near: p) else {
            moveAnchor = nil
            return
        }
        selection = hit
        switch hit {
        case let .obstacle(id):
            if let o = obstacles.first(where: { $0.id == id }) {
                moveAnchor = .obstacle(id: id, origin: o.origin)
            } else {
                moveAnchor = nil
            }
        case let .exit(id):
            if let e = exits.first(where: { $0.id == id }) {
                moveAnchor = .exit(id: id, a: e.a, b: e.b)
            }
        case let .ignition(i):
            if ignitions.indices.contains(i) {
                moveAnchor = .ignition(index: i, point: ignitions[i])
            }
        }
    }

    /// Track a drag-move — the element follows the finger, snapped and clamped inside the room.
    func updateMove(from start: Vec2, to current: Vec2) {
        guard let anchor = moveAnchor else { return }
        let delta = snap(current) - snap(start)
        switch anchor {
        case let .obstacle(id, origin):
            guard let i = obstacles.firstIndex(where: { $0.id == id }) else { return }
            let o = obstacles[i]
            obstacles[i].origin = Vec2(
                clampD(snapScalar(origin.x + delta.x), 0, max(0, worldWidth - o.size.x)),
                clampD(snapScalar(origin.y + delta.y), 0, max(0, worldHeight - o.size.y))
            )
        case let .exit(id, a, b):
            guard let i = exits.firstIndex(where: { $0.id == id }) else { return }
            exits[i] = Exit(id: id, a: clampInside(a + delta), b: clampInside(b + delta))
        case let .ignition(index, point):
            guard ignitions.indices.contains(index) else { return }
            ignitions[index] = clampInside(point + delta)
        }
    }

    func endMove() {
        moveAnchor = nil
    }

    /// Nudge the selection half a metre — the floating arrow-pad action.
    func nudgeSelection(by delta: Vec2) {
        switch selection {
        case let .obstacle(id):
            nudgeObstacle(id, by: delta)
        case let .exit(id):
            translateExit(id, by: delta)
        case let .ignition(i):
            guard ignitions.indices.contains(i) else { return }
            ignitions[i] = clampInside(snap(ignitions[i] + delta))
        case nil:
            break
        }
    }

    /// Translate an exit bodily by `delta`, keeping both ends inside the room.
    func translateExit(_ id: Int, by delta: Vec2) {
        guard let i = exits.firstIndex(where: { $0.id == id }) else { return }
        let e = exits[i]
        exits[i] = Exit(id: id, a: snap(clampInside(e.a + delta)), b: snap(clampInside(e.b + delta)))
    }

    /// Delete whatever is selected.
    func deleteSelection() {
        switch selection {
        case let .obstacle(id): obstacles.removeAll { $0.id == id }
        case let .exit(id): exits.removeAll { $0.id == id }
        case let .ignition(i): if ignitions.indices.contains(i) {
                ignitions.remove(at: i)
            }
        case nil: break
        }
        selection = nil
    }

    /// Duplicate the selected object a couple of cells down-right, and select the copy. The copy keeps
    /// the original's simulation class and prop identity.
    func duplicateSelection() {
        guard case let .obstacle(id) = selection, let o = obstacles.first(where: { $0.id == id }) else { return }
        let off = cellSize * 2
        let origin = Vec2(
            clampD(snapScalar(o.origin.x + off), 0, max(0, worldWidth - o.size.x)),
            clampD(snapScalar(o.origin.y + off), 0, max(0, worldHeight - o.size.y))
        )
        let newID = allocID()
        obstacles.append(Obstacle(id: newID, origin: origin, size: o.size, simClass: o.simClass, kind: o.kind))
        selection = .obstacle(newID)
    }

    // Selection read-outs for the floating pad.

    var selectionTitle: String? {
        switch selection {
        case let .obstacle(id):
            guard let o = obstacles.first(where: { $0.id == id }) else { return nil }
            return EditorProp.name(forKind: o.kind)
        case let .exit(id): return exits.contains { $0.id == id } ? "Exit \(id)" : nil
        case .ignition: return "Fire point"
        case nil: return nil
        }
    }

    /// The name of the prop stored on an obstacle ("Bar", "Object") — for the accessible objects list.
    func propName(for obstacle: Obstacle) -> String {
        EditorProp.name(forKind: obstacle.kind)
    }

    /// The imperative the tool pill shows while the Props tool is active — reflects the chosen prop.
    var obstaclePlacementLabel: String {
        activeProp.kind == EditorProp.object.kind ? "Place object" : "Place \(activeProp.name)"
    }

    var selectionDetail: String? {
        switch selection {
        case let .obstacle(id):
            guard let o = obstacles.first(where: { $0.id == id }) else { return nil }
            return String(format: "%.1f × %.1f m", o.size.x, o.size.y)
        case let .exit(id):
            return exits.contains { $0.id == id } ? String(format: "%.1f m clear", exitWidth(id)) : nil
        case .ignition: return "Ignition point"
        case nil: return nil
        }
    }

    var selectionIsObstacle: Bool {
        if case .obstacle = selection {
            return true
        }
        return false
    }

    var selectionIsExit: Bool {
        if case .exit = selection {
            return true
        }
        return false
    }

    /// Whether the selected element can be moved. Every prop the author places is movable in the editor;
    /// the sim-class governs only blocking and RALLY relocatability, not editor repositioning.
    var selectionIsMovable: Bool {
        selection != nil
    }

    /// The width of the selected exit, if one is selected — drives the pad's −/+ stepper.
    var selectedExitID: Int? {
        if case let .exit(id) = selection {
            return id
        }
        return nil
    }

    /// Nearest movable element to `p` within the finger radius, or `nil`.
    private func nearestSelectable(near p: Vec2) -> EditorSelection? {
        var best: (EditorSelection, Double)?
        func consider(_ sel: EditorSelection, _ dist: Double) {
            guard dist <= selectRadius else { return }
            if dist < (best?.1 ?? .infinity) {
                best = (sel, dist)
            }
        }
        for o in obstacles {
            consider(.obstacle(o.id), distanceToBox(p, origin: o.origin, size: o.size))
        }
        for e in exits {
            consider(.exit(e.id), distanceToSegment(p, e.a, e.b))
        }
        for (i, ig) in ignitions.enumerated() {
            consider(.ignition(i), p.distance(to: ig))
        }
        return best?.0
    }

    /// Drop the selection if the element it points at no longer exists (after a resize or a clear).
    private func validateSelection() {
        switch selection {
        case let .obstacle(id): if !obstacles.contains(where: { $0.id == id }) {
                selection = nil
            }
        case let .exit(id): if !exits.contains(where: { $0.id == id }) {
                selection = nil
            }
        case let .ignition(i): if !ignitions.indices.contains(i) {
                selection = nil
            }
        case nil: break
        }
    }

    /// Clamp a point inside the room (no snap — callers snap when they need to).
    private func clampInside(_ v: Vec2) -> Vec2 {
        Vec2(clampD(v.x, 0, worldWidth), clampD(v.y, 0, worldHeight))
    }

    /// Pull any element endpoints back inside the room after a resize so nothing floats off-canvas.
    /// Call this when width/height changes. Degenerate leftovers are dropped.
    func clampToBounds() {
        let w = worldWidth
        let h = worldHeight
        func c(_ v: Vec2) -> Vec2 {
            Vec2(clampD(v.x, 0, w), clampD(v.y, 0, h))
        }
        walls = walls.map { Wall(a: c($0.a), b: c($0.b)) }.filter { $0.length >= minWallLength }
        exits = exits.map { Exit(id: $0.id, a: c($0.a), b: c($0.b)) }.filter { $0.width >= minExitWidth }
        obstacles = obstacles.compactMap { o in
            let origin = c(o.origin)
            let far = c(o.origin + o.size)
            let size = Vec2(far.x - origin.x, far.y - origin.y)
            guard size.x >= minObstacleSide, size.y >= minObstacleSide else { return nil }
            var clamped = o
            clamped.origin = origin
            clamped.size = size
            return clamped // keep simClass + kind through a resize
        }
        ignitions = ignitions.map(c)
        validateSelection()
    }

    // MARK: Accessible authoring (§5.6 — VoiceOver-operable placement)

    /// A room edge a doorway can be dropped onto — the accessible alternative to dragging along a wall.
    enum RoomEdge: String, CaseIterable, Identifiable {
        case north, east, south, west
        var id: String {
            rawValue
        }

        var label: String {
            switch self {
            case .north: "Top"
            case .east: "Right"
            case .south: "Bottom"
            case .west: "Left"
            }
        }
    }

    /// The narrowest an exit may be set to via the stepper, and the stepper increment (§4.2 — 0.1 m).
    static let minEditableExit = 0.6
    static let exitStep = 0.1

    /// Add a doorway centred on the given room edge at the citable exit minimum — no drag required, so a
    /// VoiceOver user can author exits on the primary path. The floor-drain gate still governs Simulate.
    func addExit(on edge: RoomEdge) {
        let half = SafetyStandards.minExitWidth / 2
        let (a, b): (Vec2, Vec2)
        switch edge {
        case .north: a = Vec2(worldWidth / 2 - half, 0)
            b = Vec2(worldWidth / 2 + half, 0)
        case .south: a = Vec2(worldWidth / 2 - half, worldHeight)
            b = Vec2(worldWidth / 2 + half, worldHeight)
        case .west: a = Vec2(0, worldHeight / 2 - half)
            b = Vec2(0, worldHeight / 2 + half)
        case .east: a = Vec2(worldWidth, worldHeight / 2 - half)
            b = Vec2(worldWidth, worldHeight / 2 + half)
        }
        exits.append(Exit(id: allocID(), a: snap(a), b: snap(b)))
    }

    /// An exit's clear width, metres — the value the stepper reads.
    func exitWidth(_ id: Int) -> Double {
        exits.first { $0.id == id }?.width ?? 0
    }

    /// The widest an exit can grow, symmetric about its centre, before an endpoint leaves the room.
    func maxExitWidth(_ id: Int) -> Double {
        guard let exit = exits.first(where: { $0.id == id }) else { return Self.minEditableExit }
        let axis = exit.b - exit.a
        let dir = axis.length > 1e-9 ? axis.normalized : Vec2(1, 0)
        let half = min(rayToBound(from: exit.center, dir: dir), rayToBound(from: exit.center, dir: dir * -1))
        return max(Self.minEditableExit, (half * 2 / cellSize).rounded(.down) * cellSize)
    }

    /// Set an exit's clear width, growing/shrinking symmetrically about its centre along its own axis,
    /// clamped to `[minEditableExit, maxExitWidth]` so it never leaves the room.
    func setExitWidth(_ id: Int, to width: Double) {
        guard let i = exits.firstIndex(where: { $0.id == id }) else { return }
        let exit = exits[i]
        let axis = exit.b - exit.a
        let dir = axis.length > 1e-9 ? axis.normalized : Vec2(1, 0)
        let w = clampD(width, Self.minEditableExit, maxExitWidth(id))
        let half = dir * (w / 2)
        exits[i] = Exit(id: id, a: exit.center - half, b: exit.center + half)
    }

    /// Remove an exit by id — the accessible counterpart to the erase tool.
    func removeExit(_ id: Int) {
        exits.removeAll { $0.id == id }
    }

    /// Remove an object by id. Structural props are removable; the lock (V5) is only about *moving* them.
    func removeObstacle(_ id: Int) {
        obstacles.removeAll { $0.id == id }
    }

    /// Nudge an object by `delta` metres, snapped and clamped inside the room. The author may reposition
    /// any prop they placed; the sim-class only affects blocking and RALLY relocatability, not authoring.
    func nudgeObstacle(_ id: Int, by delta: Vec2) {
        guard let i = obstacles.firstIndex(where: { $0.id == id }) else { return }
        let o = obstacles[i]
        obstacles[i].origin = Vec2(
            clampD(snapScalar(o.origin.x + delta.x), 0, max(0, worldWidth - o.size.x)),
            clampD(snapScalar(o.origin.y + delta.y), 0, max(0, worldHeight - o.size.y))
        )
    }

    /// Distance (metres) from `c` along unit `dir` to the first room boundary it meets.
    private func rayToBound(from c: Vec2, dir: Vec2) -> Double {
        var t = Double.infinity
        if dir.x > 1e-9 {
            t = min(t, (worldWidth - c.x) / dir.x)
        } else if dir.x < -1e-9 {
            t = min(t, -c.x / dir.x)
        }
        if dir.y > 1e-9 {
            t = min(t, (worldHeight - c.y) / dir.y)
        } else if dir.y < -1e-9 {
            t = min(t, -c.y / dir.y)
        }
        return t
    }

    private func snapScalar(_ v: Double) -> Double {
        (v / cellSize).rounded() * cellSize
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
            if blocked.contains(coord) {
                continue
            }
            free += 1
            if field.isReachable(coord) {
                reachable += 1
            }
        }
        return free > 0 ? Double(reachable) / Double(free) : 0
    }

    /// Simulable when there's a real grid, at least one exit, and most of the floor can drain.
    var isSimulable: Bool {
        venue.isValid && reachableFloorFraction >= 0.5
    }

    /// A human reason the draft can't run yet, or `nil` when it's good to go.
    var blockingIssue: String? {
        if exits.isEmpty {
            return "Add at least one exit."
        }
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

    private func clampD(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(v, lo), hi)
    }

    /// Lower corner + positive size of the box spanned by two dragged corners.
    private func box(_ a: Vec2, _ b: Vec2) -> (Vec2, Vec2) {
        (Vec2(min(a.x, b.x), min(a.y, b.y)), Vec2(abs(b.x - a.x), abs(b.y - a.y)))
    }

    /// Remove the single closest element within the erase radius of `p`. Returns whether anything was
    /// actually removed, so a missed erase tap stays silent.
    @discardableResult
    private func erase(near p: Vec2) -> Bool {
        enum Kind { case obstacle, exit, wall, ignition }
        struct Hit { let kind: Kind
            let index: Int
            let dist: Double
        }
        var best: Hit?
        func consider(_ kind: Kind, _ index: Int, _ dist: Double) {
            guard dist <= eraseRadius else { return }
            if dist < (best?.dist ?? .infinity) {
                best = Hit(kind: kind, index: index, dist: dist)
            }
        }
        for (i, o) in obstacles.enumerated() {
            consider(.obstacle, i, distanceToBox(p, origin: o.origin, size: o.size))
        }
        for (i, e) in exits.enumerated() {
            consider(.exit, i, distanceToSegment(p, e.a, e.b))
        }
        for (i, w) in walls.enumerated() {
            consider(.wall, i, distanceToSegment(p, w.a, w.b))
        }
        for (i, ig) in ignitions.enumerated() {
            consider(.ignition, i, p.distance(to: ig))
        }
        guard let hit = best else { return false }
        switch hit.kind {
        case .obstacle: obstacles.remove(at: hit.index)
        case .exit: exits.remove(at: hit.index)
        case .wall: walls.remove(at: hit.index)
        case .ignition: ignitions.remove(at: hit.index)
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
