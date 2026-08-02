@testable import EgressEngine
import Foundation
import Testing

/// §6.5 G2 — the faster-is-slower validation. A dense crowd funnels a single ~1 m doorway set in a
/// full-width interior wall (a real walled *throat*, not an open exit). Between runs the ONLY thing that
/// changes is `SimulationConfig.panicSpeed`, the desired-speed multiplier a panicked agent applies
/// (§2.6) — same venue, same crowd, same seed — so any change in outcome is caused purely by how hard
/// panicked agents drive into the throat.
///
/// Past a critical loading the door *clogs*: the extra urgency packs the bottleneck, body compression
/// and tangential friction climb, and collective flow collapses even though each individual is trying to
/// move faster. Faster individual speed, slower collective egress — emergent from the Helbing force,
/// never scripted (§2.2). Because it is a clogging *instability* it is non-monotonic; a release-mode
/// sweep of this exact fixture (seed 11) records:
///
///     panic 1.00 → clears  89 s      panic 1.75 → GRIDLOCK
///     panic 1.25 → clears  76 s      panic 2.00 → clears  88 s
///     panic 1.50 → GRIDLOCK          panic 2.50 → GRIDLOCK
///
/// i.e. raising panic speed can gridlock a door a calmer crowd clears, and pushing it further can shake
/// the arch loose again. The test asserts the load-bearing half of that — calm clears, +50 % panic
/// gridlocks — with just two runs so the debug suite stays affordable.
@Suite("Faster is slower")
struct FasterIsSlowerTests {
    /// 260 people in a 7 m × 7 m room, all funnelling one ~1 m gap in a full-width interior wall down to
    /// the exit just beyond it. Dense enough that the pre-throat wedge crosses the panic band, tight
    /// enough that panicked shoving can jam it.
    private func throatFixture() -> (VenueModel, SimulationConfig) {
        let room = 7.0
        let gap = 1.2 // rasterises to a ~1.0 m throat on the 0.25 m grid
        let cells = Int((room / 0.25).rounded())
        let geometry = GridGeometry(size: GridSize(width: cells, height: cells))
        let barrierY = 1.5
        let cx = room / 2
        let venue = VenueModel(
            id: 0, name: "throat", type: .nightclub, geometry: geometry,
            walls: [
                Wall(a: Vec2(0, barrierY), b: Vec2(cx - gap / 2, barrierY)),
                Wall(a: Vec2(cx + gap / 2, barrierY), b: Vec2(room, barrierY)),
            ],
            exits: [Exit(id: 0, a: Vec2(cx - gap / 2, 0.0), b: Vec2(cx + gap / 2, 0.0))]
        )
        return (venue, SimulationConfig(agentCount: 260, maxValidatedAgents: 400, seed: 11))
    }

    /// Run the throat crowd at one panic multiplier. Returns the clearance time if the crowd fully
    /// evacuates, or `nil` if the door gridlocks — detected when the active count stops falling for a
    /// 20 s window while people remain (a stable arch), so a clogged run ends in ~1 min instead of
    /// grinding to the 6 min cap.
    private func clearanceOrGridlock(panicSpeed: Double) -> TimeInterval? {
        let (venue, base) = throatFixture()
        var config = base
        config.panicSpeed = panicSpeed
        let sim = Simulation(venue: venue, config: config)

        let stallWindow = 1200 // frames (20 s) with no net evacuation ⇒ a stable clog
        let hardCap = 9000 // 150 s backstop
        var frames = 0
        var fewestActive = Int.max
        var lastProgressFrame = 0
        while !sim.isComplete, frames < hardCap {
            sim.step(dt: 1.0 / 60.0)
            frames += 1
            let active = sim.metrics.lastActiveCount
            if active < fewestActive {
                fewestActive = active
                lastProgressFrame = frames
            } else if frames - lastProgressFrame >= stallWindow {
                return nil // evacuation has stalled with people still inside — gridlocked
            }
        }
        return sim.metrics.clearanceTime
    }

    @Test("More panic speed gridlocks a door that clears when the crowd is calmer")
    func fasterIsSlower() {
        let calm = clearanceOrGridlock(panicSpeed: 1.0) // panicked agents at base speed — the fast baseline
        let panicked = clearanceOrGridlock(panicSpeed: 1.5) // +50 % desired speed — enough to jam this throat

        // The calm crowd genuinely evacuates, and well within any reasonable budget.
        #expect(calm != nil)
        #expect((calm ?? .infinity) < 120)
        // Raising ONLY the panic-speed multiplier gridlocks the same crowd at the same door: the extra
        // urgency clogs the throat and collective egress collapses. Faster individuals, slower crowd (§2.2).
        #expect(panicked == nil)
    }

    @Test("The panic-speed knob leaves an uncrowded run untouched")
    func knobIsInertWhenNobodyPanics() {
        // A handful of agents never reach the panic density band, so no agent's speed multiplier is ever
        // consulted — changing it must not change the run at all (proves the knob only bites via panic).
        let geometry = GridGeometry(size: GridSize(width: 24, height: 24))
        let venue = VenueModel(
            id: 0, name: "sparse", type: .nightclub, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.25, 6.0), b: Vec2(3.75, 6.0))]
        )
        func clear(_ panic: Double) -> TimeInterval {
            var config = SimulationConfig(agentCount: 6, maxValidatedAgents: 200, seed: 3)
            config.panicSpeed = panic
            let sim = Simulation(venue: venue, config: config)
            var frames = 0
            while !sim.isComplete, frames < 6000 { sim.step(dt: 1.0 / 60.0); frames += 1 }
            return sim.metrics.clearance
        }
        #expect(clear(1.5) == clear(3.0))
    }
}
