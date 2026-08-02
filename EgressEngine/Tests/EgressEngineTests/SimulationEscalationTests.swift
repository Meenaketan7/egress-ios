import Testing

@testable import EgressEngine

/// E4b — the escalation tracker driven live from inside `Simulation` (§3.3). Reuses the proven crowded
/// and fire scenarios, then reads the escalations the run raised as a side effect.
@Suite("Simulation escalation")
struct SimulationEscalationTests {
    /// 120 agents draining a 0.5 m door in a 6 m × 6 m nightclub — a dense, sustained jam.
    private func crowded(seed: UInt64 = 11) -> Simulation {
        let geometry = GridGeometry(size: GridSize(width: 24, height: 24))
        let venue = VenueModel(
            id: 0, name: "crowd", type: .nightclub, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.75, 6.0), b: Vec2(3.25, 6.0))]
        )
        return Simulation(venue: venue, config: SimulationConfig(agentCount: 120, maxValidatedAgents: 200, seed: seed))
    }

    /// The casualty scenario: 60 agents, a 0.5 m door, fire at the throat.
    private func trap(seed: UInt64 = 3) -> Simulation {
        let geometry = GridGeometry(size: GridSize(width: 20, height: 20))
        let venue = VenueModel(
            id: 0, name: "trap", type: .concertHall, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.25, 5.0), b: Vec2(2.75, 5.0))]
        )
        let config = SimulationConfig(agentCount: 60, maxValidatedAgents: 200, seed: seed, ignition: [Vec2(2.5, 4.5)])
        return Simulation(venue: venue, config: config)
    }

    private func run(_ sim: Simulation, maxFrames: Int) {
        var frames = 0
        while !sim.isComplete, frames < maxFrames {
            sim.step(dt: 1.0 / 60.0)
            frames += 1
        }
    }

    @Test("A dense crowd through a tight door raises density escalations, mirrored into the log")
    func denseCrowdEscalates() {
        let sim = crowded()
        run(sim, maxFrames: 12000)
        #expect(!sim.escalations.isEmpty)
        #expect(sim.escalations.contains { EscalationBand.densityLadder.contains($0.band) })
        #expect(sim.eventLog.events.contains { $0.kind == .densityThresholdCrossed })
    }

    @Test("Escalations obey the cooldown end to end — none land within 6 s of the previous")
    func escalationsAreSpaced() {
        let sim = crowded()
        run(sim, maxFrames: 12000)
        for (earlier, later) in zip(sim.escalations, sim.escalations.dropFirst()) {
            #expect(later.time - earlier.time >= VerdictConstants.escalationCooldown - 1e-9)
        }
    }

    @Test("A fire that downs people raises the casualty escalation")
    func casualtyEscalates() {
        let sim = trap()
        run(sim, maxFrames: 6000)
        #expect(sim.metrics.casualties > 0)
        #expect(sim.escalations.contains { $0.band == .casualty })
    }

    @Test("Escalations are deterministic for a fixed seed")
    func escalationsAreDeterministic() {
        let first = crowded()
        let second = crowded()
        run(first, maxFrames: 12000)
        run(second, maxFrames: 12000)
        #expect(first.escalations == second.escalations)
    }
}
