import Testing

@testable import EgressEngine

@Suite("Simulation")
struct SimulationTests {
    /// A square hall with a doorway centred on the bottom edge. 20×20 cells = 5 m × 5 m.
    private func hall(count: Int = 30, seed: UInt64 = 1, walls: [Wall] = [], exits: [Exit]? = nil) -> Simulation {
        let geometry = GridGeometry(size: GridSize(width: 20, height: 20))
        let doorway = exits ?? [Exit(id: 0, a: Vec2(2.0, 5.0), b: Vec2(3.0, 5.0))]
        let venue = VenueModel(
            id: 0, name: "hall", type: .concertHall, geometry: geometry, walls: walls, exits: doorway
        )
        return Simulation(venue: venue, config: SimulationConfig(agentCount: count, maxValidatedAgents: 200, seed: seed))
    }

    private func run(_ sim: Simulation, maxFrames: Int) {
        var frames = 0
        while !sim.isComplete, frames < maxFrames {
            sim.step(dt: 1.0 / 60.0)
            frames += 1
        }
    }

    @Test("agents spawn, follow the flow field, and everyone evacuates")
    func everyoneEvacuates() {
        let sim = hall(count: 40)
        run(sim, maxFrames: 4000)
        let live = sim.snapshot().live
        #expect(sim.isComplete)
        #expect(live.evacuatedCount == 40)
        #expect(live.activeCount == 0)
        #expect(live.fractionOut == 1.0)
    }

    @Test("same seed reproduces an identical run")
    func deterministic() {
        let simA = hall(seed: 7)
        let simB = hall(seed: 7)
        for _ in 0 ..< 300 {
            simA.step(dt: 1.0 / 60.0)
            simB.step(dt: 1.0 / 60.0)
        }
        #expect(simA.snapshot().agents == simB.snapshot().agents)
    }

    @Test("the integrator stays finite and in-bounds mid-run — no NaN, no blow-up")
    func integratorIsStable() {
        let sim = hall(count: 50, seed: 3)
        for _ in 0 ..< 120 { sim.step(dt: 1.0 / 60.0) } // ~2 s in, agents still moving
        for agent in sim.snapshot().agents {
            #expect(agent.position.x.isFinite && agent.position.y.isFinite)
            #expect(agent.position.x >= 0 && agent.position.x <= 5.0)
            #expect(agent.position.y >= 0 && agent.position.y <= 5.0)
        }
    }

    @Test("agents detour around a wall instead of walking through it")
    func routesAroundWall() {
        // A wall across most of the width, gap on the right, forces the crowd to funnel around it.
        let wall = Wall(a: Vec2(0.0, 3.0), b: Vec2(4.0, 3.0)) // open only where x ∈ [4, 5]
        let sim = hall(count: 30, walls: [wall])
        run(sim, maxFrames: 6000)
        #expect(sim.isComplete)
        #expect(sim.snapshot().live.evacuatedCount == 30)
    }

    // MARK: - Crowd dynamics (step 4b — social force)

    private func crowdedHall(count: Int, seed: UInt64, exit: Exit) -> Simulation {
        let geometry = GridGeometry(size: GridSize(width: 24, height: 24)) // 6 m × 6 m
        let venue = VenueModel(id: 0, name: "crowd", type: .nightclub, geometry: geometry, exits: [exit])
        return Simulation(venue: venue, config: SimulationConfig(agentCount: count, maxValidatedAgents: 200, seed: seed))
    }

    @Test("the crowd stays finite and in-bounds under load — no NaN, no blow-up")
    func stableUnderLoad() {
        // 120 agents draining through a tight 0.5 m door keep a dense contact jam active the whole run.
        let sim = crowdedHall(count: 120, seed: 11, exit: Exit(id: 0, a: Vec2(2.75, 6.0), b: Vec2(3.25, 6.0)))
        for _ in 0 ..< 6000 { sim.step(dt: 1.0 / 60.0) } // ~12 000 substeps at H = 1/120 s
        for agent in sim.snapshot().agents {
            #expect(agent.position.x.isFinite && agent.position.y.isFinite)
            #expect(agent.position.x >= 0 && agent.position.x <= 6.0)
            #expect(agent.position.y >= 0 && agent.position.y <= 6.0)
        }
    }

    @Test("contact forces slow the crowd but never deadlock it — everyone still gets out")
    func fullyEvacuatesUnderCrowding() {
        let sim = crowdedHall(count: 100, seed: 2, exit: Exit(id: 0, a: Vec2(2.4, 6.0), b: Vec2(3.6, 6.0)))
        run(sim, maxFrames: 9000)
        #expect(sim.isComplete)
        #expect(sim.snapshot().live.evacuatedCount == 100)
    }
}
