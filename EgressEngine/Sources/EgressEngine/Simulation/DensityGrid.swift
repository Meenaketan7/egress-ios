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
}
