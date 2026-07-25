import Foundation

/// Pure mapping between world space (metres) and grid space (cells).
/// Cell size comes from `SafetyStandards`, so the grid stays metrically true.
public struct GridGeometry: Sendable {
    public let cellSize: Double
    public let size: GridSize

    public init(size: GridSize, cellSize: Double = SafetyStandards.cellSize) {
        self.size = size
        self.cellSize = cellSize
    }

    /// The cell containing a world point (floor division).
    public func cell(for world: Vec2) -> GridCoord {
        GridCoord(Int(floor(world.x / cellSize)), Int(floor(world.y / cellSize)))
    }

    /// Centre of a cell, in metres.
    public func worldCenter(of c: GridCoord) -> Vec2 {
        Vec2((Double(c.x) + 0.5) * cellSize, (Double(c.y) + 0.5) * cellSize)
    }

    /// Lower corner (origin) of a cell, in metres.
    public func worldOrigin(of c: GridCoord) -> Vec2 {
        Vec2(Double(c.x) * cellSize, Double(c.y) * cellSize)
    }

    /// World extent of the whole grid, in metres.
    public var worldWidth: Double { Double(size.width) * cellSize }
    public var worldHeight: Double { Double(size.height) * cellSize }
}