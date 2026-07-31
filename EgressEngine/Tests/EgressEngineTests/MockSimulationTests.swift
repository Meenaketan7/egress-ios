@testable import EgressEngine
import Testing

@Suite("MockSimulation")
struct MockSimulationTests {
    /// A small square room with one exit on the bottom edge.
    private func makeVenue() -> VenueModel {
        let geo = GridGeometry(size: GridSize(width: 40, height: 40)) // 10 m × 10 m
        let exit = Exit(id: 0, a: Vec2(4.5, 10), b: Vec2(5.5, 10))
        return VenueModel(id: 0, name: "Test Room", type: .office, geometry: geo, exits: [exit])
    }

    @Test("Snapshot shape matches the config and venue")
    func snapshotShape() {
        let sim = MockSimulation(venue: makeVenue(), config: SimulationConfig(agentCount: 50, seed: 1))
        let snap = sim.snapshot()
        #expect(snap.agents.count == 50)
        #expect(snap.density.size.count == 1600)
        #expect(snap.live.activeCount == 50)
        #expect(snap.time == 0)
    }

    @Test("Same seed reproduces an identical run")
    func determinism() {
        let venue = makeVenue()
        let a = MockSimulation(venue: venue, config: SimulationConfig(agentCount: 30, seed: 123))
        let b = MockSimulation(venue: venue, config: SimulationConfig(agentCount: 30, seed: 123))
        for _ in 0 ..< 120 {
            a.step(dt: 1.0 / 60.0)
            b.step(dt: 1.0 / 60.0)
        }
        #expect(a.snapshot() == b.snapshot())
    }

    @Test("Different seeds place agents differently")
    func seedsDiffer() {
        let venue = makeVenue()
        let a = MockSimulation(venue: venue, config: SimulationConfig(agentCount: 30, seed: 1))
        let b = MockSimulation(venue: venue, config: SimulationConfig(agentCount: 30, seed: 2))
        #expect(a.snapshot().agents != b.snapshot().agents)
    }

    @Test("Everyone reaches the exit and the run completes")
    func reachesCompletion() {
        let sim = MockSimulation(venue: makeVenue(), config: SimulationConfig(agentCount: 40, seed: 5))
        var steps = 0
        while !sim.isComplete, steps < 3000 {
            sim.step(dt: 1.0 / 60.0)
            steps += 1
        }
        #expect(sim.isComplete)
        let snap = sim.snapshot()
        #expect(snap.live.fractionOut == 1.0)
        #expect(snap.live.activeCount == 0)
    }

    @Test("dt is clamped so a long frame can't blow up the step")
    func clampsDt() {
        let sim = MockSimulation(venue: makeVenue(), config: SimulationConfig(agentCount: 10, seed: 5))
        sim.step(dt: 100) // absurd frame gap
        #expect(sim.snapshot().time <= 1.0 / 30.0 + 1e-9)
    }

    @Test("Fire ignites and smoke appears after the seed delay")
    func hazardsBloom() {
        let sim = MockSimulation(venue: makeVenue(), config: SimulationConfig(agentCount: 10, seed: 5))
        #expect(sim.snapshot().hazards.isEmpty) // inert at t=0
        for _ in 0 ..< 600 { sim.step(dt: 1.0 / 60.0) } // ~10 s
        #expect(!sim.snapshot().hazards.isEmpty)
        #expect(!sim.snapshot().hazards.fire.isEmpty)
    }
}
