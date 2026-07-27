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

// MARK: - Obstacle

/// A blocking region. Furniture is relocatable; structure is not.
public struct Obstacle: Identifiable, Equatable, Sendable {
    public let id: Int
    /// Axis-aligned box: lower corner + size, in metres.
    public var origin: Vec2
    public var size: Vec2
    public var isRelocatable: Bool
    public init(id: Int, origin: Vec2, size: Vec2, isRelocatable: Bool) {
        self.id = id
        self.origin = origin
        self.size = size
        self.isRelocatable = isRelocatable
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
