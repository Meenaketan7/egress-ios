/// The smoke diffusion field (§2.7). Opacity in `[0,1]` per cell: burning cells emit `SMOKE_PRODUCTION`
/// per second, then every cell relaxes toward its 4-neighbour mean by `SMOKE_DIFFUSION` and loses
/// `SMOKE_DECAY` per second, clamped to `[0,1]`. Smoke deliberately outruns the flame and **never
/// blocks movement** — it later cuts awareness (disorientation, herding). A pure, RNG-free value fed
/// the burning cells each tick, so it unit-tests with no `Simulation`.
public struct SmokeField: Sendable, Equatable {
    public let size: GridSize
    /// Opacity per cell, indexed by `size.index(of:)`.
    public private(set) var values: [Double]

    public init(size: GridSize) {
        self.size = size
        values = [Double](repeating: 0, count: size.count)
    }

    /// Advance one hazard tick. `sources` are the currently burning cells; `dt` is the hazard step.
    public mutating func tick(dt: Double, sources: [GridCoord]) {
        guard !size.isEmpty, dt > 0 else { return }

        // Burning cells emit smoke (a per-second rate).
        for source in sources {
            if let index = size.index(of: source) {
                values[index] = min(1, values[index] + SimConstants.smokeProduction * dt)
            }
        }

        // Diffuse toward the neighbour mean and decay, from a snapshot so the pass is order-independent.
        let previous = values
        for index in values.indices {
            let mean = neighbourMean(previous, at: index, cell: size.coord(atIndex: index))
            var next = previous[index] + SimConstants.smokeDiffusion * (mean - previous[index])
            next -= SimConstants.smokeDecay * previous[index] * dt
            values[index] = min(1, max(0, next))
        }
    }

    /// Opacity at a cell (off-grid reads as clear).
    public func value(at cell: GridCoord) -> Double {
        guard let index = size.index(of: cell) else { return 0 }
        return values[index]
    }

    /// Highest opacity anywhere this frame.
    public var peak: Double { values.max() ?? 0 }

    /// Non-clear cells for the render snapshot — sparse, since early runs touch only a few.
    public var opacity: [GridCoord: Double] {
        var result: [GridCoord: Double] = [:]
        for index in values.indices where values[index] > 0.001 {
            result[size.coord(atIndex: index)] = values[index]
        }
        return result
    }

    /// Mean opacity of a cell's in-bounds 4-neighbours; falls back to the cell itself on a lone cell.
    private func neighbourMean(_ field: [Double], at index: Int, cell: GridCoord) -> Double {
        let orthogonal = [
            GridCoord(cell.x, cell.y - 1), GridCoord(cell.x, cell.y + 1),
            GridCoord(cell.x - 1, cell.y), GridCoord(cell.x + 1, cell.y),
        ]
        var sum = 0.0
        var count = 0
        for neighbour in orthogonal {
            if let neighbourIndex = size.index(of: neighbour) {
                sum += field[neighbourIndex]
                count += 1
            }
        }
        return count == 0 ? field[index] : sum / Double(count)
    }
}
