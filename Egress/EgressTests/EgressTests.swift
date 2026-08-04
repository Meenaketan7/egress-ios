@testable import Egress
import EgressEngine
import Foundation
import Testing

/// App-level guards for the parts of the core journey that live above the engine — chiefly that the
/// `SimulationController`'s fixed-step accumulator makes an in-app run *reproducible*, matching the
/// engine test driver regardless of how irregular the real display frames are (§4.1 determinism).
@MainActor
struct EgressTests {
    /// A reference run: the same venue/config stepped at the canonical fixed 1/60, exactly as the engine
    /// suite drives it. Returns the resolved clearance and Safety Score.
    private func reference(_ venue: VenueModel, _ config: SimulationConfig) -> (clearance: Double, score: Int) {
        let sim = Simulation(venue: venue, config: config)
        var frames = 0
        while !sim.isComplete, frames < 60000 {
            sim.step(dt: 1.0 / 60.0)
            frames += 1
        }
        return (sim.metrics.clearance, SafetyScore(metrics: sim.metrics).value)
    }

    @Test("in-app run is deterministic under irregular frame pacing")
    func fixedStepDeterminism() throws {
        let venue = SampleVenue.hall()
        let config = SimulationConfig(agentCount: 40, maxValidatedAgents: 200, seed: 7)
        let expected = reference(venue, config)

        let controller = SimulationController(venue: venue, config: config)
        controller.play()

        // Feed jittery frame timestamps — the pacing a real 60 Hz display with dropped frames produces.
        // Each gap stays under the controller's catch-up budget so no backlog is dropped.
        let gaps = [1.0 / 60, 1.0 / 45, 1.0 / 90, 1.0 / 30, 1.0 / 72]
        var now = Date(timeIntervalSinceReferenceDate: 0)
        var i = 0
        while controller.result == nil, i < 200_000 {
            now += gaps[i % gaps.count]
            controller.advance(to: now)
            i += 1
        }

        let result = try #require(controller.result)
        #expect(result.metrics.clearance == expected.clearance)
        #expect(result.score.value == expected.score)
    }
}
