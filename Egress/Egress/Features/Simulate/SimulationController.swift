import EgressEngine
import Observation
import SwiftUI

/// Owns one running simulation and the latest frame the canvas draws. Deliberately blind to
/// *which* simulation it drives: today `MockSimulation`, at S1-exit the real `Simulation`,
/// swapped on the single marked line — everything above `SimulationRunning` stays untouched.
/// `@MainActor` because it feeds SwiftUI; `@Observable` so the canvas and HUD redraw when
/// `snapshot` changes.
@MainActor
@Observable
final class SimulationController {
    let venue: VenueModel
    private(set) var snapshot: SimulationSnapshot
    private(set) var isRunning = false

    private var sim: any SimulationRunning
    private let config: SimulationConfig
    private var lastFrame: Date?

    init(venue: VenueModel, config: SimulationConfig) {
        self.venue = venue
        self.config = config
        let sim = Simulation(venue: venue, config: config) // real engine (swapped from MockSimulation at S1)
        self.sim = sim
        snapshot = sim.snapshot()
    }
    

    /// Start or resume. Clears the frame baseline so the first tick after resuming isn't a huge dt.
    func play() {
        guard !sim.isComplete else { return }
        lastFrame = nil
        isRunning = true
    }

    func pause() { isRunning = false }

    /// Rebuild from the same seed — identical, reproducible playback.
    func reset() {
        sim = Simulation(venue: venue, config: config)
        snapshot = sim.snapshot()
        lastFrame = nil
        isRunning = false
    }

    /// Advance to the wall-clock time of the current animation frame. Called once per display
    /// refresh from the canvas's `TimelineView`. `MockSimulation` clamps dt internally, so a
    /// dropped frame or a resume-after-pause can never blow the step up.
    func advance(to frame: Date) {
        guard isRunning, !sim.isComplete else { return }
        defer { lastFrame = frame }
        guard let previous = lastFrame else { return } // first frame only sets the baseline
        let dt = frame.timeIntervalSince(previous)
        guard dt > 0 else { return }
        sim.step(dt: dt)
        snapshot = sim.snapshot()
        if sim.isComplete { isRunning = false }
    }
}