@testable import EgressEngine
import Testing

/// The core-journey capstone (§0.9): open a failing layout → verdict → RALLY names a geometry fix →
/// Apply → re-run → visibly better score. Everything below the app runs here end to end.
@Suite("Apply & re-run")
struct ApplyRerunTests {
    private func runToEnd(venue: VenueModel, config: SimulationConfig) -> Metrics {
        let sim = Simulation(venue: venue, config: config)
        var frames = 0
        while !sim.isComplete, frames < 24000 { // up to 400 s (past any cap)
            sim.step(dt: 1.0 / 60.0)
            frames += 1
        }
        return sim.metrics
    }

    @Test("RALLY's fix, applied and re-run on the same crowd, improves the Safety Score")
    func applyAndRerunImprovesScore() {
        // 220 people funnelling a single 0.5 m exit in a 12 m nightclub — so many for so tight a door
        // that, once agents panic and shove into the throat, the crowd never clears within the cap.
        // That gridlock is the demo's failing layout; widening the exit is what rescues it.
        let geometry = GridGeometry(size: GridSize(width: 48, height: 48)) // 12 m × 12 m
        let venue = VenueModel(
            id: 0, name: "club", type: .nightclub, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(5.75, 12.0), b: Vec2(6.25, 12.0))]
        )
        let config = SimulationConfig(agentCount: 220, maxValidatedAgents: 400, seed: 11)

        // First run — the original layout.
        let before = runToEnd(venue: venue, config: config)
        let verdictBefore = VerdictRules.default.evaluate(before)
        #expect(verdictBefore.level != .pass) // there really is a problem to fix

        // RALLY proposes a grounded fix; apply it and re-run the identical crowd.
        guard let fix = RallyCoach.default.suggest(for: verdictBefore, metrics: before, in: venue) else {
            Issue.record("expected RALLY to propose a fix")
            return
        }
        #expect(fix.feasibility(in: venue).isFeasible)
        let improved = fix.apply(to: venue)
        let after = runToEnd(venue: improved, config: config)

        let scoreBefore = SafetyScore(metrics: before).value
        let scoreAfter = SafetyScore(metrics: after).value
        #expect(scoreAfter > scoreBefore) // the widened door visibly improves the score
        #expect(after.clearance < before.clearance) // …because the crowd clears faster
    }
}
