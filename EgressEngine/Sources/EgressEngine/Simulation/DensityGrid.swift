/// Crowd density in persons·m⁻², one value per grid cell — the input to the density-glow
/// layer and the HUD "worst density" chip. A pure value: the simulation rebuilds it each
/// tick and hands it across the render boundary inside a `SimulationSnapshot`.
public struct DensityGrid: Sendable, Equatable {
    public let size: GridSize
    /// Row-major, one value per cell (`values.count == size.count`), in persons·m⁻².
    public private(set) var values: [Double]

    /// A zeroed grid — the pre-run state.
    public init(size: GridSize) {
        self.size = size
        values = Array(repeating: 0, count: size.count)
    }

    public init(size: GridSize, values: [Double]) {
        precondition(values.count == size.count, "DensityGrid needs exactly one value per cell")
        self.size = size
        self.values = values
    }

    public func value(at c: GridCoord) -> Double {
        guard let i = size.index(of: c) else { return 0 }
        return values[i]
    }

    public mutating func set(_ v: Double, at c: GridCoord) {
        guard let i = size.index(of: c) else { return }
        values[i] = v
    }

    /// The single highest cell density — the HUD's "worst density" readout.
    public var peak: Double { values.max() ?? 0 }

    /// A cell at the highest density (row-major-first on ties), or `nil` for an empty or all-zero grid —
    /// the location the density-crossing escalation and the glow's hotspot point at.
    public var peakCell: GridCoord? {
        guard let index = values.indices.max(by: { values[$0] < values[$1] }), values[index] > 0 else { return nil }
        return size.coord(atIndex: index)
    }

        /// Builds the smoothed density field for a frame (plan §2.8): bin each body's centre into its
    /// cell, run a separable box blur of radius `r = round(radius / cellSize)` cells, then divide
    /// each cell's summed count by the kernel's physical area → persons·m⁻². Pure and O(cells·r), so
    /// the simulation rebuilds it once per frame and hands it across the render boundary.
    public static func sampled(
        positions: [Vec2],
        in geometry: GridGeometry,
        radius: Double = SimConstants.densityRadius
    ) -> DensityGrid {
        let size = geometry.size
        guard !size.isEmpty else { return DensityGrid(size: size) }

        // 1. Bin: one raw head-count per cell; bodies off the grid are ignored.
        var counts = [Double](repeating: 0, count: size.count)
        for point in positions {
            if let index = size.index(of: geometry.cell(for: point)) { counts[index] += 1 }
        }

        // 2. Separable box blur → each cell holds the summed count over its (2r+1)² neighbourhood.
        let radiusCells = max(0, Int((radius / geometry.cellSize).rounded()))
        let summed = boxBlurSum(counts, size: size, radius: radiusCells)

        // 3. Normalise by the kernel's physical area → persons·m⁻².
        let kernelArea = Double((2 * radiusCells + 1) * (2 * radiusCells + 1)) * geometry.cellSize * geometry.cellSize
        return DensityGrid(size: size, values: summed.map { $0 / kernelArea })
    }

    /// A separable box-blur pass pair (horizontal then vertical) leaving each cell holding the **sum**
    /// of its neighbours within `radius` cells. Out-of-grid neighbours contribute 0, so edge cells sum
    /// fewer bodies and a fixed divisor reads them as slightly lower density — where the walls are anyway.
    private static func boxBlurSum(_ source: [Double], size: GridSize, radius: Int) -> [Double] {
        guard radius > 0 else { return source }
        let width = size.width
        let height = size.height

        var horizontal = [Double](repeating: 0, count: source.count)
        for y in 0 ..< height {
            let row = y * width
            for x in 0 ..< width {
                var sum = 0.0
                for k in max(0, x - radius) ... min(width - 1, x + radius) { sum += source[row + k] }
                horizontal[row + x] = sum
            }
        }

        var vertical = [Double](repeating: 0, count: source.count)
        for x in 0 ..< width {
            for y in 0 ..< height {
                var sum = 0.0
                for k in max(0, y - radius) ... min(height - 1, y + radius) { sum += horizontal[k * width + x] }
                vertical[y * width + x] = sum
            }
        }
        return vertical
    }
}
