import Foundation

/// End-of-run analysis folded across a whole simulation (plan §2.8): how long the crowd took to
/// clear, the worst density reached (and where/when), and how much time people spent in the at-risk
/// band. Distinct from `LiveMetrics` (cheap per-frame HUD counters) — these are the inputs the
/// Safety Score and verdict read. The simulation owns one, folds each frame in via `record`, and
/// exposes it once the run resolves. Kept a pure value (fed precomputed `(id, cell)` pairs and a
/// `DensityGrid`) so it unit-tests with no `Simulation`.
public struct Metrics: Sendable, Equatable {
    /// Population that spawned — the denominator for `atRiskFraction`.
    public let spawnedCount: Int
    /// The reasoned egress goal for this venue (§2.9), seconds — what clearance is scored against.
    public let clearanceTarget: TimeInterval
    /// Hard run cap, seconds — the clearance value reported when the crowd never fully clears.
    public let timeCap: TimeInterval

    /// Sim time the last active agent evacuated; `nil` until (and unless) everyone is out.
    public private(set) var clearanceTime: TimeInterval?
    /// Highest smoothed cell density seen this run, persons·m⁻².
    public private(set) var peakDensity: Double
    /// Where the peak occurred — the `jamFormed` marker's location.
    public private(set) var peakLocation: GridCoord?
    /// When the peak occurred, sim seconds.
    public private(set) var peakTime: TimeInterval
    /// Casualties recorded so far. Stays 0 until hazards land (a later S2 step).
    public private(set) var casualties: Int
    /// Active movers in the most recent recorded frame — the trapped count once a run ends at the cap.
    public private(set) var lastActiveCount: Int

    /// Per-agent seconds banked in the at-risk band, keyed by agent id — the raw at-risk store.
    private var dwell: [Int: TimeInterval]

    public init(spawnedCount: Int, clearanceTarget: TimeInterval, timeCap: TimeInterval) {
        self.spawnedCount = spawnedCount
        self.clearanceTarget = clearanceTarget
        self.timeCap = timeCap
        clearanceTime = nil
        peakDensity = 0
        peakLocation = nil
        peakTime = 0
        casualties = 0
        lastActiveCount = 0
        dwell = [:]
    }

    /// Fold one rendered frame into the running totals. `activeCells` is `(agent id, its grid cell)`
    /// for every still-active agent; `dt` is the sim time this frame advanced.
    public mutating func record(
        time: TimeInterval,
        dt: TimeInterval,
        density: DensityGrid,
        activeCells: [(id: Int, cell: GridCoord)]
    ) {
        lastActiveCount = activeCells.count

        // Peak density (with where + when) — the single worst cell across the whole run.
        if density.peak > peakDensity {
            peakDensity = density.peak
            peakTime = time
            if let index = density.values.firstIndex(of: density.peak) {
                peakLocation = density.size.coord(atIndex: index)
            }
        }

        // At-risk dwell: each active agent standing in a ≥ 5 p·m⁻² cell banks this frame's seconds.
        for entry in activeCells where density.value(at: entry.cell) >= SafetyStandards.densityAtRisk {
            dwell[entry.id, default: 0] += dt
        }

        // Clearance: the first frame with nobody left to move (and time has actually advanced).
        if clearanceTime == nil, activeCells.isEmpty, time > 0 {
            clearanceTime = time
        }
    }

    /// Record one person struck down by a hazard — called once per agent as it first falls (§2.7).
    public mutating func recordCasualty() { casualties += 1 }

    /// Clearance time, seconds — the time cap if the crowd never fully cleared.
    public var clearance: TimeInterval { clearanceTime ?? timeCap }
    /// Occupants still trying to escape when the run ended — non-zero only when the crowd never
    /// cleared (clearance fell back to the cap). Rule 3's "trapped at the cap" count; casualties,
    /// which aren't active, are counted separately under rule 1.
    public var trappedCount: Int { clearanceTime == nil ? lastActiveCount : 0 }
    /// Total person-seconds banked in the at-risk band across the whole crowd.
    public var atRiskPersonSeconds: TimeInterval { dwell.values.reduce(0, +) }
    /// Agents who spent at least `AT_RISK_DWELL` (3 s) in the at-risk band.
    public var atRiskAgents: Int { dwell.values.filter { $0 >= SimConstants.atRiskDwell }.count }
    /// Fraction of the spawned crowd that counts as at-risk — the verdict's `RISK` input.
    public var atRiskFraction: Double {
        spawnedCount == 0 ? 0 : Double(atRiskAgents) / Double(spawnedCount)
    }
}