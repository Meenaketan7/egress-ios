/// The companion of `FlowField` (build plan §2.4, item 3): for every cell, the distance to the
/// nearest wall or obstacle and the outward normal pointing away from it. It feeds the §2.2 soft
/// wall force, which keeps a cushion between agents and walls and rounds their paths at corners —
/// the polish the hard wall-slide can't give on its own.
///
/// Built once per run (like `FlowField`) by a multi-source flood from every impassable cell, each
/// open cell inheriting the nearest wall's coordinate; distance and normal then come from the true
/// geometry between the two centres. The grid boundary is *not* a wall here — real venue perimeters
/// are authored as walls with a doorway gap, and treating the edge as solid would wrongly repel
/// agents back out of an exit that sits on it.
public struct WallField: Sendable {
    public let size: GridSize
    private let distanceField: [Double]
    private let normalField: [Vec2]

    public init(size: GridSize, cellSize: Double, blocked: Set<GridCoord>) {
        self.size = size
        let count = max(0, size.count)

        // Multi-source flood: every open cell inherits the coordinate of the nearest wall cell.
        var nearest = [GridCoord?](repeating: nil, count: count)
        var frontier: [GridCoord] = []
        for cell in blocked {
            guard let idx = size.index(of: cell), nearest[idx] == nil else { continue }
            nearest[idx] = cell
            frontier.append(cell)
        }
        var head = 0
        while head < frontier.count {
            let cell = frontier[head]
            head += 1
            guard let idx = size.index(of: cell), let source = nearest[idx] else { continue }
            for neighbour in cell.vonNeumannNeighbours {
                guard let neighbourIndex = size.index(of: neighbour), nearest[neighbourIndex] == nil else { continue }
                nearest[neighbourIndex] = source
                frontier.append(neighbour)
            }
        }

        // Turn each cell's nearest wall into a metric distance and an outward unit normal.
        var distances = [Double](repeating: .greatestFiniteMagnitude, count: count)
        var normals = [Vec2](repeating: .zero, count: count)
        for i in 0 ..< count {
            guard let source = nearest[i] else { continue }
            let cell = size.coord(atIndex: i)
            let centre = Vec2((Double(cell.x) + 0.5) * cellSize, (Double(cell.y) + 0.5) * cellSize)
            let wallCentre = Vec2((Double(source.x) + 0.5) * cellSize, (Double(source.y) + 0.5) * cellSize)
            distances[i] = centre.distance(to: wallCentre)
            normals[i] = (centre - wallCentre).normalized
        }
        distanceField = distances
        normalField = normals
    }

    /// Metres to the nearest wall; `.greatestFiniteMagnitude` when the venue has no walls at all
    /// (or the cell is off-grid), so the force guard prunes it to zero.
    public func distance(at cell: GridCoord) -> Double {
        guard let idx = size.index(of: cell) else { return .greatestFiniteMagnitude }
        return distanceField[idx]
    }

    /// Unit vector pointing away from the nearest wall; `.zero` on a wall cell itself or where
    /// there is no wall.
    public func normal(at cell: GridCoord) -> Vec2 {
        guard let idx = size.index(of: cell) else { return .zero }
        return normalField[idx]
    }
}
