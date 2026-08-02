import Testing

@testable import EgressEngine

/// E3 — the run lifecycle written into `RunEventLog` from inside `Simulation` (§A.5). These reuse the
/// proven scenarios from `SimulationTests`, then read the log the run produced as a side effect.
@Suite("Simulation events")
struct SimulationEventsTests {
    /// A square hall with a 1 m doorway on the bottom edge — the clean-run baseline.
    private func hall(count: Int, seed: UInt64 = 1) -> Simulation {
        let geometry = GridGeometry(size: GridSize(width: 20, height: 20))
        let venue = VenueModel(
            id: 0, name: "hall", type: .concertHall, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.0, 5.0), b: Vec2(3.0, 5.0))]
        )
        return Simulation(venue: venue, config: SimulationConfig(agentCount: count, maxValidatedAgents: 200, seed: seed))
    }

    /// The proven casualty scenario from `SimulationTests`: 60 agents, a 0.5 m door, fire at the throat.
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

    @Test("A clean run logs the alarm at t0 and ends 'all evacuated', with no fire events")
    func cleanRunLifecycle() {
        let sim = hall(count: 40)
        run(sim, maxFrames: 4000)
        let log = sim.eventLog
        let alarms = log.events.filter { $0.kind == .alarmTriggered }
        #expect(alarms.count == 1)
        #expect(alarms.first?.time == 0)
        #expect(!log.events.contains { $0.kind == .ignition })
        #expect(!log.events.contains { $0.kind == .agentInjured })
        let ended = log.events.last { $0.kind == .simEnded }
        #expect(ended?.detail == "all evacuated")
        let summary = log.summary()
        #expect(summary.casualties == 0)
        #expect(summary.endReason == "all evacuated")
    }

    @Test("The end-of-run marker is logged exactly once, even if stepping continues")
    func simEndedFiresOnce() {
        let sim = hall(count: 30)
        run(sim, maxFrames: 4000)
        for _ in 0 ..< 20 { sim.step(dt: 1.0 / 60.0) } // keep poking a finished run
        #expect(sim.eventLog.events.filter { $0.kind == .simEnded }.count == 1)
    }

    @Test("A fire that overruns the crowd logs ignition, casualties and a reroute")
    func fireRunLifecycle() {
        let sim = trap()
        run(sim, maxFrames: 6000)
        let log = sim.eventLog
        #expect(log.events.contains { $0.kind == .ignition })
        #expect(log.events.contains { $0.kind == .flowFieldRecomputed }) // fire changed the passable set
        #expect(log.events.contains { $0.kind == .agentInjured })
        #expect(log.events.contains { $0.kind == .simEnded })

        // The digest's casualty tallies agree with the metrics fold and with each other.
        let summary = log.summary()
        #expect(summary.injuries == sim.metrics.casualties) // both count the injury transition
        #expect(summary.casualties <= summary.injuries) // a killed agent was injured first
        #expect(summary.injuries > 0)
    }

    @Test("The event log is deterministic for a fixed seed")
    func logIsDeterministic() {
        let first = trap()
        let second = trap()
        run(first, maxFrames: 6000)
        run(second, maxFrames: 6000)
        #expect(first.eventLog.events == second.eventLog.events)
    }
}
