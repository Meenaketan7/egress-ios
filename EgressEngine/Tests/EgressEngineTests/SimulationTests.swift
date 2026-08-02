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

    // MARK: - Pocket-clog regression (§2.4)

    @Test("The Vault's flush-top geometry strands no one behind the bar")
    func vaultLeavesNoOneFrozen() {
        // The pocket clog: when the bar and stage left a thin open strip behind them, a handful of
        // isolated agents were pinned to the top edge (y ≈ 0) by the soft wall force and never
        // evacuated — the run hit the time cap even though the exit was clear. Seating the bar and
        // stage flush to the top wall removes that strip (VenuePreset.nightclub); this guards it stays
        // removed by running the furnished floor and requiring a full drain with no one left up top.
        let preset = VenuePreset.nightclub
        let sim = Simulation(
            venue: preset.venue,
            config: SimulationConfig(agentCount: preset.crowd, maxValidatedAgents: 300, seed: 1)
        )
        var frames = 0
        while !sim.isComplete, frames < 40000 { sim.step(dt: 1.0 / 60.0); frames += 1 }

        let geometry = preset.venue.geometry
        let frozenInStrip = sim.snapshot().agents.filter {
            $0.status.isActive && geometry.cell(for: $0.position).y <= 6 // the top strip, behind the bar
        }
        #expect(frozenInStrip.isEmpty, "agents stranded in the top strip: \(frozenInStrip.count)")
        #expect(sim.snapshot().live.evacuatedCount == preset.crowd) // no one left behind the bar
        #expect(sim.snapshot().live.activeCount == 0)
    }

    // MARK: - Run metrics (step 4c — Metrics wiring)

    @Test("A full run records clearance, a real peak density, and the venue's derived cap")
    func recordsRunMetrics() {
        let sim = hall(count: 40)
        run(sim, maxFrames: 4000)
        #expect(sim.isComplete)
        let metrics = sim.metrics
        // The concert-hall target (§2.9) flows through to both the target and the derived cap.
        #expect(metrics.clearanceTarget == 180)
        #expect(metrics.timeCap == 540) // clamp(3 × 180, 300, 600)
        #expect(metrics.spawnedCount == 40)
        // Everyone got out, so clearance latched somewhere below the cap.
        #expect(metrics.clearance > 0)
        #expect(metrics.clearance < metrics.timeCap)
        // A 40-strong crowd funnelling one doorway drove some real density, with a located worst cell.
        #expect(metrics.peakDensity > 0)
        #expect(metrics.peakLocation != nil)
    }

    @Test("Clearance is the sim time at which the run completes")
    func clearanceMarksCompletion() {
        let sim = hall(count: 30)
        run(sim, maxFrames: 4000)
        #expect(sim.isComplete)
        // The last active agent evacuates on the completing step, so clearance is that final time.
        #expect(sim.metrics.clearance == sim.snapshot().time)
    }

    // MARK: - Hazards (step H3 — fire wiring)

    private func burningHall(count: Int, seed: UInt64, ignition: [Vec2]) -> Simulation {
        let geometry = GridGeometry(size: GridSize(width: 24, height: 24)) // 6 m × 6 m
        let venue = VenueModel(
            id: 0, name: "fire", type: .concertHall, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.5, 6.0), b: Vec2(3.5, 6.0))]
        )
        let config = SimulationConfig(agentCount: count, maxValidatedAgents: 200, seed: seed, ignition: ignition)
        return Simulation(venue: venue, config: config)
    }

    @Test("A placed fire renders into the snapshot and the run stays deterministic")
    func fireRendersAndIsDeterministic() {
        func trace() -> (sawFire: Bool, sawSmoke: Bool, evacuated: Int) {
            let sim = burningHall(count: 30, seed: 5, ignition: [Vec2(1.0, 1.0)])
            var sawFire = false
            var sawSmoke = false
            for _ in 0 ..< 1500 { // 25 s
                sim.step(dt: 1.0 / 60.0)
                let hazards = sim.snapshot().hazards
                if !hazards.fire.isEmpty { sawFire = true }
                if !hazards.smoke.isEmpty { sawSmoke = true }
            }
            return (sawFire, sawSmoke, sim.snapshot().live.evacuatedCount)
        }
        let first = trace()
        let second = trace()
        #expect(first.sawFire) // fire rendered during the run
        #expect(first.sawSmoke) // smoke rendered during the run
        #expect(first.evacuated == second.evacuated) // same seed ⇒ identical outcome
    }

    @Test("Fire at the doorway holds people back versus a clear run")
    func fireAtDoorwaySlowsEvacuation() {
        func evacuated(after seconds: Double, ignition: [Vec2]) -> Int {
            let sim = burningHall(count: 30, seed: 8, ignition: ignition)
            for _ in 0 ..< Int(seconds * 60) { sim.step(dt: 1.0 / 60.0) }
            return sim.snapshot().live.evacuatedCount
        }
        let clear = evacuated(after: 12, ignition: [])
        let blazing = evacuated(after: 12, ignition: [Vec2(3.0, 5.5)]) // right at the exit throat
        #expect(blazing < clear) // flames at the mouth hold people back
    }

    @Test("Fire that overruns a packed crowd produces casualties and a FAIL verdict")
    func fireCausesCasualtiesAndFails() {
        // A tight room draining through a 0.5 m door; fire at the throat spreads back into the jam.
        let geometry = GridGeometry(size: GridSize(width: 20, height: 20)) // 5 m × 5 m
        let venue = VenueModel(
            id: 0, name: "trap", type: .concertHall, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.25, 5.0), b: Vec2(2.75, 5.0))]
        )
        let config = SimulationConfig(agentCount: 60, maxValidatedAgents: 200, seed: 3, ignition: [Vec2(2.5, 4.5)])
        let sim = Simulation(venue: venue, config: config)
        var frames = 0
        while !sim.isComplete, frames < 6000 { // up to 100 s
            sim.step(dt: 1.0 / 60.0)
            frames += 1
        }
        #expect(sim.metrics.casualties > 0) // fire caught people in the jam
        #expect(VerdictRules.default.evaluate(sim.metrics).level == .fail) // rule 1
    }
}
