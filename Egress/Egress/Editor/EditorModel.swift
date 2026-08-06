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
    case select, wall, exit, erase, obstacle, fire, water

    var id: String {
        rawValue
    }

    var group: EditorToolGroup {
        switch self {
        case .select, .wall, .exit, .erase: .build
        case .obstacle: .props
        case .fire, .water: .hazards
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
        case .water: "Water"
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
        case .water: "Fill water"
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
        case .water: "water.waves"
        }
    }

    /// The one-line instruction shown beneath the canvas for the selected tool.
    var hint: String {
        switch self {
        case .select: "Tap an item to select it, then drag or use the arrows to move it."
        case .wall: "Drag to draw an impassable wall."
        case .exit: "Drag along an edge to place a doorway."
        case .obstacle: "Drag a box to drop furniture people route around."
        case .erase: "Tap a wall, exit, object, water, or fire to remove it."
        case .fire: "Tap to drop a fire ignition point the crowd must avoid."
        case .water: "Drag a box to flood an area the crowd routes around."
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
        case .water: .egHazardFlood
        }
    }
}

// MARK: - EditorSelection

/// The element the Select tool currently has picked, so the floating pad can move/configure it.
enum EditorSelection: Equatable {
    case obstacle(Int)
    case exit(Int)
    case ignition(Int)
    case water(Int)
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

    /// The pan/zoom camera over the free-form canvas (design's ReactFlow-style board). View-state, but
    /// it lives here with `tool`/`selection`/`draft` so gestures and the ± buttons drive one source.
    var camera = EditorCamera()

    private(set) var walls: [Wall] = []
    private(set) var exits: [Exit] = []
    private(set) var obstacles: [Obstacle] = []
    /// Standing-water flood zones the crowd routes around — a static hazard, sibling to fire (§2.7).
    private(set) var waterZones: [WaterZone] = []
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

    /// Memoised room-exterior cells (see `roomExterior`), keyed on a signature of the enclosure inputs
    /// so a pure camera pan never re-floods — only a real wall/exit/bounds change recomputes it.
    @ObservationIgnored private var exteriorCache: (signature: Int, cells: Set<GridCoord>)?

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
        ignitions = preset.ignitions // e.g. The Vault's seeded fire — the money-shot FAIL
        nextID = ((exits.map(\.id) + obstacles.map(\.id)).max() ?? 0) + 1
    }

    // MARK: Derived venue

    private var cellSize: Double {
        SafetyStandards.cellSize
    }

    var worldWidth: Double {
        contentBounds.size.x
    }

    var worldHeight: Double {
        contentBounds.size.y
    }

    /// The author-space rectangle that will simulate — the "room". It's the base floor (0,0 …
    /// width,height) *unioned* with the bounding box of everything drawn, snapped out to whole cells.
    /// So the walls decide the shape and size (draw beyond the base floor and the room grows to fit),
    /// yet a fresh draft and every furnished preset still start at a sensible, fully-drawing room —
    /// the fixed-rectangle constraint is gone without cutting off any open floor. When nothing is drawn
    /// outside the base floor (the common case, and every preset) this is byte-identical to the old grid.
    var contentBounds: WorldRect {
        var minX = 0.0, minY = 0.0
        var maxX = widthMetres, maxY = heightMetres // base floor anchored at the origin
        if let raw = rawContentBounds {
            minX = min(minX, raw.origin.x)
            minY = min(minY, raw.origin.y)
            maxX = max(maxX, raw.maxCorner.x)
            maxY = max(maxY, raw.maxCorner.y)
        }
        // Snap outwards to whole cells so the derived grid is always exact.
        minX = (minX / cellSize).rounded(.down) * cellSize
        minY = (minY / cellSize).rounded(.down) * cellSize
        maxX = (maxX / cellSize).rounded(.up) * cellSize
        maxY = (maxY / cellSize).rounded(.up) * cellSize
        return WorldRect(origin: Vec2(minX, minY), size: Vec2(maxX - minX, maxY - minY))
    }

    /// The tight bounding box of the *drawn* content only (walls, exits, objects, water, fire) —
    /// ignoring the base floor. `nil` when nothing has been drawn. Drives "fit to content".
    private var rawContentBounds: WorldRect? {
        var minX = Double.infinity, minY = Double.infinity
        var maxX = -Double.infinity, maxY = -Double.infinity
        func include(_ p: Vec2) {
            minX = min(minX, p.x)
            minY = min(minY, p.y)
            maxX = max(maxX, p.x)
            maxY = max(maxY, p.y)
        }
        for w in walls {
            include(w.a)
            include(w.b)
        }
        for e in exits {
            include(e.a)
            include(e.b)
        }
        for o in obstacles {
            include(o.origin)
            include(o.origin + o.size)
        }
        for z in waterZones {
            include(z.origin)
            include(z.origin + z.size)
        }
        for ig in ignitions {
            include(ig)
        }
        guard minX.isFinite else { return nil }
        return WorldRect(origin: Vec2(minX, minY), size: Vec2(maxX - minX, maxY - minY))
    }

    /// The grid the room's metre extent maps to (0.25 m cells), derived from `contentBounds`.
    var geometry: GridGeometry {
        let b = contentBounds
        let w = max(1, Int((b.size.x / cellSize).rounded()))
        let h = max(1, Int((b.size.y / cellSize).rounded()))
        return GridGeometry(size: GridSize(width: w, height: h))
    }

    /// The room's **exterior** cells in the normalised grid frame — everything outside the shape the
    /// walls enclose (`RoomEnclosure`), so an L-, T- or angled room simulates as the drawn shape rather
    /// than its bounding rectangle. Empty when the walls don't enclose anything (bare presets, sketches),
    /// leaving the whole grid as floor. Memoised on a signature of walls/exits/bounds so panning the
    /// camera never re-floods.
    var roomExterior: Set<GridCoord> {
        let off = contentBounds.origin
        let geo = geometry
        var hasher = Hasher()
        hasher.combine(geo.size.width)
        hasher.combine(geo.size.height)
        hasher.combine(off)
        for w in walls {
            hasher.combine(w.a)
            hasher.combine(w.b)
        }
        for e in exits {
            hasher.combine(e.a)
            hasher.combine(e.b)
        }
        let signature = hasher.finalize()
        if let cache = exteriorCache, cache.signature == signature {
            return cache.cells
        }

        let normWalls = walls.map { Wall(a: $0.a - off, b: $0.b - off) }
        let normExits = exits.map { Exit(id: $0.id, a: $0.a - off, b: $0.b - off) }
        let cells = RoomEnclosure.exterior(walls: normWalls, exits: normExits, geometry: geo)
        exteriorCache = (signature, cells)
        return cells
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? type.displayName : trimmed
    }

    /// The immutable venue the simulator runs — a snapshot of the current draft, **normalised** into the
    /// engine's coordinate frame: every element is translated by `-contentBounds.origin` so the drawing
    /// (which may extend left/above the base floor in author space) lands in `[0,W] × [0,H]`. The engine
    /// itself never sees the free-form canvas — only this tight bounded grid.
    var venue: VenueModel {
        let off = contentBounds.origin
        return VenueModel(
            id: 0,
            name: displayName,
            type: type,
            geometry: geometry,
            walls: walls.map { Wall(a: $0.a - off, b: $0.b - off) },
            exits: exits.map { Exit(id: $0.id, a: $0.a - off, b: $0.b - off) },
            obstacles: obstacles.map { var o = $0
                o.origin = $0.origin - off
                return o
            },
            water: waterZones.map { var z = $0
                z.origin = $0.origin - off
                return z
            },
            blockedCells: roomExterior
        )
    }

    /// Reproducible config — a fixed seed so re-running the same draft replays the same crowd, plus any
    /// editor-placed fire (translated by the same offset as `venue`, so ignition points still land on
    /// the right cells) so the authored hazard actually burns in the run.
    var config: SimulationConfig {
        let off = contentBounds.origin
        return SimulationConfig(
            agentCount: crowd, maxValidatedAgents: 300, seed: 42,
            ignition: ignitions.map { $0 - off }
        )
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
        case .water:
            let (origin, size) = box(a, b)
            if size.x >= minObstacleSide, size.y >= minObstacleSide {
                waterZones.append(WaterZone(id: allocID(), origin: origin, size: size))
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

    /// Remove every drawn element and hazard (base floor size, type and crowd are kept).
    func clearElements() {
        walls.removeAll()
        exits.removeAll()
        obstacles.removeAll()
        waterZones.removeAll()
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

    /// Remove every standing-water flood zone.
    func clearWater() {
        waterZones.removeAll()
        if case .water = selection {
            selection = nil
        }
    }

    /// Re-anchor the room to exactly what's been drawn: translate every element so the drawing's
    /// bounding box sits at the origin, and shrink the base floor to match. This is how the room becomes
    /// *any* size — draw a small (or huge, or L-shaped) layout, then fit the floor tightly to it.
    func fitBaseToContent() {
        guard let raw = rawContentBounds, raw.size.x > 0, raw.size.y > 0 else { return }
        let off = raw.origin
        walls = walls.map { Wall(a: $0.a - off, b: $0.b - off) }
        exits = exits.map { Exit(id: $0.id, a: $0.a - off, b: $0.b - off) }
        obstacles = obstacles.map { var o = $0
            o.origin = $0.origin - off
            return o
        }
        waterZones = waterZones.map { var z = $0
            z.origin = $0.origin - off
            return z
        }
        ignitions = ignitions.map { $0 - off }
        widthMetres = (raw.size.x / cellSize).rounded() * cellSize
        heightMetres = (raw.size.y / cellSize).rounded() * cellSize
    }

    // MARK: Select & move (§3.5 direct manipulation)

    private let selectRadius = 0.9
    private enum MoveAnchor {
        case obstacle(id: Int, origin: Vec2)
        case exit(id: Int, a: Vec2, b: Vec2)
        case ignition(index: Int, point: Vec2)
        case water(id: Int, origin: Vec2)
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
        case let .water(id):
            if let z = waterZones.first(where: { $0.id == id }) {
                moveAnchor = .water(id: id, origin: z.origin)
            } else {
                moveAnchor = nil
            }
        }
    }

    /// Track a drag-move — the element follows the finger, snapped to the grid. Nothing clamps to a room
    /// any more: the canvas is free, so an element may be dragged anywhere (the room grows to fit it).
    func updateMove(from start: Vec2, to current: Vec2) {
        guard let anchor = moveAnchor else { return }
        let delta = snap(current) - snap(start)
        switch anchor {
        case let .obstacle(id, origin):
            guard let i = obstacles.firstIndex(where: { $0.id == id }) else { return }
            obstacles[i].origin = Vec2(snapScalar(origin.x + delta.x), snapScalar(origin.y + delta.y))
        case let .exit(id, a, b):
            guard let i = exits.firstIndex(where: { $0.id == id }) else { return }
            exits[i] = Exit(id: id, a: a + delta, b: b + delta)
        case let .ignition(index, point):
            guard ignitions.indices.contains(index) else { return }
            ignitions[index] = point + delta
        case let .water(id, origin):
            guard let i = waterZones.firstIndex(where: { $0.id == id }) else { return }
            waterZones[i].origin = Vec2(snapScalar(origin.x + delta.x), snapScalar(origin.y + delta.y))
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
            ignitions[i] = snap(ignitions[i] + delta)
        case let .water(id):
            nudgeWater(id, by: delta)
        case nil:
            break
        }
    }

    /// Translate an exit bodily by `delta` (free canvas — no clamp; the room grows to fit).
    func translateExit(_ id: Int, by delta: Vec2) {
        guard let i = exits.firstIndex(where: { $0.id == id }) else { return }
        let e = exits[i]
        exits[i] = Exit(id: id, a: snap(e.a + delta), b: snap(e.b + delta))
    }

    /// Delete whatever is selected.
    func deleteSelection() {
        switch selection {
        case let .obstacle(id): obstacles.removeAll { $0.id == id }
        case let .exit(id): exits.removeAll { $0.id == id }
        case let .ignition(i): if ignitions.indices.contains(i) {
                ignitions.remove(at: i)
            }
        case let .water(id): waterZones.removeAll { $0.id == id }
        case nil: break
        }
        selection = nil
    }

    /// Duplicate the selected object a couple of cells down-right, and select the copy. The copy keeps
    /// the original's simulation class and prop identity.
    func duplicateSelection() {
        guard case let .obstacle(id) = selection, let o = obstacles.first(where: { $0.id == id }) else { return }
        let off = cellSize * 2
        let origin = Vec2(snapScalar(o.origin.x + off), snapScalar(o.origin.y + off))
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
        case let .water(id): return waterZones.contains { $0.id == id } ? "Water" : nil
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
        case let .water(id):
            guard let z = waterZones.first(where: { $0.id == id }) else { return nil }
            return String(format: "%.1f × %.1f m flooded", z.size.x, z.size.y)
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
        for z in waterZones {
            consider(.water(z.id), distanceToBox(p, origin: z.origin, size: z.size))
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
        case let .water(id): if !waterZones.contains(where: { $0.id == id }) {
                selection = nil
            }
        case nil: break
        }
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
        let bounds = contentBounds
        let lo = bounds.origin, hi = bounds.maxCorner, mid = bounds.center
        let half = SafetyStandards.minExitWidth / 2
        let (a, b): (Vec2, Vec2)
        switch edge {
        case .north: a = Vec2(mid.x - half, lo.y)
            b = Vec2(mid.x + half, lo.y)
        case .south: a = Vec2(mid.x - half, hi.y)
            b = Vec2(mid.x + half, hi.y)
        case .west: a = Vec2(lo.x, mid.y - half)
            b = Vec2(lo.x, mid.y + half)
        case .east: a = Vec2(hi.x, mid.y - half)
            b = Vec2(hi.x, mid.y + half)
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

    /// Nudge an object by `delta` metres, snapped to the grid. The author may reposition any prop they
    /// placed anywhere on the free canvas; the sim-class only affects blocking and RALLY relocatability.
    func nudgeObstacle(_ id: Int, by delta: Vec2) {
        guard let i = obstacles.firstIndex(where: { $0.id == id }) else { return }
        let o = obstacles[i]
        obstacles[i].origin = Vec2(snapScalar(o.origin.x + delta.x), snapScalar(o.origin.y + delta.y))
    }

    /// Nudge a water flood zone by `delta` metres, snapped to the grid.
    func nudgeWater(_ id: Int, by delta: Vec2) {
        guard let i = waterZones.firstIndex(where: { $0.id == id }) else { return }
        let z = waterZones[i]
        waterZones[i].origin = Vec2(snapScalar(z.origin.x + delta.x), snapScalar(z.origin.y + delta.y))
    }

    /// Remove a water zone by id — the accessible counterpart to the erase tool.
    func removeWater(_ id: Int) {
        waterZones.removeAll { $0.id == id }
    }

    /// Distance (metres) from `c` along unit `dir` to the first room boundary (`contentBounds`) it meets.
    private func rayToBound(from c: Vec2, dir: Vec2) -> Double {
        let bounds = contentBounds
        let lo = bounds.origin, hi = bounds.maxCorner
        var t = Double.infinity
        if dir.x > 1e-9 {
            t = min(t, (hi.x - c.x) / dir.x)
        } else if dir.x < -1e-9 {
            t = min(t, (lo.x - c.x) / dir.x)
        }
        if dir.y > 1e-9 {
            t = min(t, (hi.y - c.y) / dir.y)
        } else if dir.y < -1e-9 {
            t = min(t, (lo.y - c.y) / dir.y)
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

    /// Snap a world point to the 0.25 m grid. No clamping — the canvas is free, so points may sit
    /// anywhere (including left of / above the base floor); `contentBounds` grows to enclose them.
    private func snap(_ p: Vec2) -> Vec2 {
        Vec2(snapScalar(p.x), snapScalar(p.y))
    }

    /// Clamp a scalar to `[lo, hi]` — still used to bound the exit clear-width stepper to its room-fit.
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
        enum Kind { case obstacle, exit, wall, ignition, water }
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
        for (i, z) in waterZones.enumerated() {
            consider(.water, i, distanceToBox(p, origin: z.origin, size: z.size))
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
        case .water: waterZones.remove(at: hit.index)
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
