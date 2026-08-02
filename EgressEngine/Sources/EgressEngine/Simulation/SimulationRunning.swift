// MARK: - SimulationConfig

/// Inputs that parameterise a run. Grows in S1–S2 (crowd mix, alarm delay, scenario
/// presets); the fields here are everything the mock and the render loop need today.
public struct SimulationConfig: Sendable {
    public var agentCount: Int
    /// Performance-budget clamp (PATCH-02). Counts above this still run, but the HUD shows the
    /// quiet "above the validated performance budget" notice rather than silently degrading.
    public var maxValidatedAgents: Int
    /// Seed for every stochastic choice — identical seed ⇒ identical run.
    public var seed: UInt64
    /// Editor-placed fire ignition points, in metres (world space). Empty ⇒ no fire (§2.7).
    public var ignition: [Vec2]
    /// Desired-speed multiplier for a panicked agent (§2.6 arousal). Defaults to the calibrated
    /// `SimConstants.panicArousal` (1.5), so an unset run is byte-identical to before. The
    /// faster-is-slower validation sweep (§6.5 G2) varies this: past a bottleneck, a *higher* panic
    /// speed can make the crowd clear *slower*, because the extra shoving jams the throat.
    public var panicSpeed: Double

    public init(
        agentCount: Int = 200,
        maxValidatedAgents: Int = 200,
        seed: UInt64 = 0,
        ignition: [Vec2] = [],
        panicSpeed: Double = SimConstants.panicArousal
    ) {
        self.agentCount = agentCount
        self.maxValidatedAgents = maxValidatedAgents
        self.seed = seed
        self.ignition = ignition
        self.panicSpeed = panicSpeed
    }

    /// True when the requested count exceeds the validated performance budget.
    public var isAboveBudget: Bool { agentCount > maxValidatedAgents }
}

// MARK: - SimulationRunning

/// The abstraction the app renders against. The entire canvas, HUD, gestures and camera are
/// built and demoed against `MockSimulation` (S0), then swapped to the real `Simulation`
/// (S1) with no change above this line. This is the contract that keeps the two developers
/// unblocked: if the engine slips, the UI still demos; if the UI slips, the engine still tests.
public protocol SimulationRunning: AnyObject {
    /// Advance by `dt` seconds. Implementations clamp `dt` to ≤ 1/30 s internally so a
    /// dropped frame can never make the physics explode.
    func step(dt: Double)

    /// The current render / concurrency contract for this frame.
    func snapshot() -> SimulationSnapshot

    /// True once the run has resolved — everyone out, the time cap, or a casualty stop.
    var isComplete: Bool { get }
}
