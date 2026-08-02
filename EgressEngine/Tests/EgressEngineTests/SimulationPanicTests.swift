import Testing

@testable import EgressEngine

/// The §2.6 arousal machine driven live from inside `Simulation`. Panic must actually engage under
/// crowding or fire (so the faster-is-slower failure mode can emerge, §2.2), stay gated while the room
/// is calm, and never break determinism — emotion is a pure observer of density + fire, drawing no RNG.
@Suite("Simulation panic")
struct SimulationPanicTests {
    /// 120 agents draining a 0.5 m door in a 6 m × 6 m room — a dense, sustained jam whose throat
    /// crushes past the at-risk band.
    private func crowded(seed: UInt64 = 11) -> Simulation {
        let geometry = GridGeometry(size: GridSize(width: 24, height: 24))
        let venue = VenueModel(
            id: 0, name: "crowd", type: .nightclub, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.75, 6.0), b: Vec2(3.25, 6.0))]
        )
        return Simulation(venue: venue, config: SimulationConfig(agentCount: 120, maxValidatedAgents: 200, seed: seed))
    }

    /// A handful of agents in the same room behind a wide 1.5 m door — never packs, so never panics.
    private func sparse(seed: UInt64 = 11) -> Simulation {
        let geometry = GridGeometry(size: GridSize(width: 24, height: 24))
        let venue = VenueModel(
            id: 0, name: "sparse", type: .nightclub, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.25, 6.0), b: Vec2(3.75, 6.0))]
        )
        return Simulation(venue: venue, config: SimulationConfig(agentCount: 4, maxValidatedAgents: 200, seed: seed))
    }

    /// Steps a run to completion (or a frame cap), reporting whether any agent was ever panicked.
    private func runObservingPanic(_ sim: Simulation, maxFrames: Int) -> Bool {
        var sawPanic = false
        var frames = 0
        while !sim.isComplete, frames < maxFrames {
            sim.step(dt: 1.0 / 60.0)
            if sim.snapshot().agents.contains(where: { $0.emotion == .panicked }) { sawPanic = true }
            frames += 1
        }
        return sawPanic
    }

    @Test("A dense crowd through a tight door drives agents to panic")
    func denseCrowdPanics() {
        #expect(runObservingPanic(crowded(), maxFrames: 12000))
    }

    @Test("A sparse, uncrowded room never panics anyone")
    func sparseRoomStaysCalm() {
        #expect(!runObservingPanic(sparse(), maxFrames: 3000))
    }

    @Test("Live emotion keeps the run deterministic for a fixed seed")
    func panicIsDeterministic() {
        let first = crowded()
        let second = crowded()
        _ = runObservingPanic(first, maxFrames: 12000)
        _ = runObservingPanic(second, maxFrames: 12000)
        #expect(first.metrics.clearance == second.metrics.clearance)
    }
}
