// MARK: - GridCoord

/// Integer cell coordinate on the simulation grid.
public struct GridCoord: Hashable, Sendable {
    public var x: Int
    public var y: Int
    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    /// 4-connected neighbours (up, down, left, right) — the flow field's connectivity.
    public var vonNeumannNeighbours: [GridCoord] {
        [
            GridCoord(x, y - 1),
            GridCoord(x, y + 1),
            GridCoord(x - 1, y),
            GridCoord(x + 1, y)
        ]
    }
}

// MARK: - GridSize

/// Grid dimensions in cells.
public struct GridSize: Hashable, Sendable {
    public let width: Int
    public let height: Int
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /// Total cell count — the length of a flat per-cell array.
    public var count: Int {
        width * height
    }

    /// True when the grid has no cells (either dimension ≤ 0).
    public var isEmpty: Bool {
        width <= 0 || height <= 0
    }

    public func contains(_ c: GridCoord) -> Bool {
        c.x >= 0 && c.x < width && c.y >= 0 && c.y < height
    }

    /// Row-major linear index for flat-array storage; `nil` if out of bounds.
    public func index(of c: GridCoord) -> Int? {
        guard contains(c) else { return nil }
        return c.y * width + c.x
    }

    /// Inverse of `index(of:)`.
    public func coord(atIndex i: Int) -> GridCoord {
        GridCoord(i % width, i / width)
    }
}
