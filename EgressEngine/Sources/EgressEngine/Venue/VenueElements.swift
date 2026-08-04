// MARK: - Wall

/// An impassable barrier segment, in metres.
public struct Wall: Equatable, Sendable {
    public var a: Vec2
    public var b: Vec2
    public init(a: Vec2, b: Vec2) {
        self.a = a
        self.b = b
    }

    /// Length of the wall segment, in metres.
    public var length: Double {
        a.distance(to: b)
    }
}

// MARK: - Exit

/// An evacuation exit — the doorway span (a…b) agents flow toward.
public struct Exit: Identifiable, Equatable, Sendable {
    public let id: Int
    public var a: Vec2
    public var b: Vec2
    public init(id: Int, a: Vec2, b: Vec2) {
        self.id = id
        self.a = a
        self.b = b
    }

    /// Clear width, in metres — the value the cyan callout shows.
    public var width: Double {
        a.distance(to: b)
    }

    /// Doorway midpoint — the flow-field seed point.
    public var center: Vec2 {
        (a + b) / 2
    }
}

// MARK: - ObstacleClass

/// How the simulation treats a prop. Relocatable furniture and fixed structure both block movement —
/// the split governs only whether RALLY may propose *moving* the prop — while decor is sim-inert and
/// never blocks a body (design's "RELOCATABLE · STRUCTURAL · DECOR" prop legend).
public enum ObstacleClass: String, Sendable, Equatable, CaseIterable {
    case relocatable, structural, decor
}

// MARK: - Obstacle

/// A prop on the floor. Relocatable furniture and fixed structure block movement; decor is inert.
public struct Obstacle: Identifiable, Equatable, Sendable {
    public let id: Int
    /// Axis-aligned box: lower corner + size, in metres.
    public var origin: Vec2
    public var size: Vec2
    /// The prop's simulation class — drives blocking (decor never blocks) and RALLY relocatability.
    public var simClass: ObstacleClass
    /// Opaque prop identity (e.g. "bar", "stage"); "object" for a plain freeform box. UI-facing only —
    /// the engine never branches on it (cf. `DecorTile.kind`).
    public var kind: String

    public init(id: Int, origin: Vec2, size: Vec2, simClass: ObstacleClass, kind: String = "object") {
        self.id = id
        self.origin = origin
        self.size = size
        self.simClass = simClass
        self.kind = kind
    }

    /// Back-compatible initialiser: relocatable furniture (`true`) vs fixed structure (`false`).
    public init(id: Int, origin: Vec2, size: Vec2, isRelocatable: Bool) {
        self.init(id: id, origin: origin, size: size, simClass: isRelocatable ? .relocatable : .structural)
    }

    /// True for relocatable furniture — the only class RALLY may propose moving.
    public var isRelocatable: Bool {
        simClass == .relocatable
    }

    /// Fixed structure — locked in the editor, and routes are planned around it (V5).
    public var isStructural: Bool {
        simClass == .structural
    }

    /// Whether the prop rasterises into blocked cells. Decor is sim-inert; every other class blocks.
    public var blocksMovement: Bool {
        simClass != .decor
    }

    /// Floor area occupied, in m².
    public var area: Double {
        size.x * size.y
    }

    /// True if a world point falls inside the box (half-open on the far edges).
    public func contains(_ p: Vec2) -> Bool {
        p.x >= origin.x && p.x < origin.x + size.x &&
            p.y >= origin.y && p.y < origin.y + size.y
    }
}

// MARK: - DecorTile

/// Sim-inert decoration — rendered, but ignored by the simulation.
public struct DecorTile: Identifiable, Equatable, Sendable {
    public let id: Int
    public var cell: GridCoord
    public var kind: String // sprite/tile identifier; opaque to the engine
    public init(id: Int, cell: GridCoord, kind: String) {
        self.id = id
        self.cell = cell
        self.kind = kind
    }
}
