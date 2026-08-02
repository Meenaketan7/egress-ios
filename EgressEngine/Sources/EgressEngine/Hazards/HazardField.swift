/// The room's live hazards for one run (§2.7) — a fire cellular automaton and the smoke it feeds,
/// advanced together on a fixed 15 Hz clock decoupled from the physics substep. Owns both fields,
/// hands the physics loop the impassable/harmful fire cells, and renders to a `HazardSnapshot`. A
/// value type seeded once from the flammable mask and ignition points, so it unit-tests on its own.
public struct HazardField: Sendable, Equatable {
    public private(set) var fire: FireAutomaton
    public private(set) var smoke: SmokeField
    /// Unspent frame time waiting to be discharged in whole 15 Hz hazard ticks.
    private var accumulator: Double

    public init(size: GridSize, flammable: [Bool], ignition: [GridCoord]) {
        fire = FireAutomaton(size: size, flammable: flammable, ignition: ignition)
        smoke = SmokeField(size: size)
        accumulator = 0
    }

    /// Advance the hazards by a frame's worth of time, discharged in fixed 15 Hz ticks. Fire spreads
    /// (drawing `rng`), then the smoke field is fed that tick's burning cells.
    public mutating func advance(by dt: Double, rng: inout SeededRNG) {
        guard dt > 0 else { return }
        accumulator += dt
        while accumulator >= SimConstants.hazardStep {
            fire.tick(dt: SimConstants.hazardStep, rng: &rng)
            smoke.tick(dt: SimConstants.hazardStep, sources: fire.burningCells)
            accumulator -= SimConstants.hazardStep
        }
    }

    /// Burning + igniting cells — impassable for the flow field and harmful to any agent in them.
    public var activeFire: Set<GridCoord> { fire.activeFire }

    /// Any fire or smoke currently present.
    public var isActive: Bool { !fire.activeFire.isEmpty || smoke.peak > 0 }

    /// The render channel for this frame — fire intensity and smoke opacity per touched cell.
    public var snapshot: HazardSnapshot {
        HazardSnapshot(fire: fire.intensity, smoke: smoke.opacity)
    }
}
