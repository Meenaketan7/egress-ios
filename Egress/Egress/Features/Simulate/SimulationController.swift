import EgressEngine
import Observation
import SwiftUI

/// Owns one running simulation, the latest frame the canvas draws, and — once the run resolves — the
/// end-of-run `RunResult` (verdict, Safety Score, RALLY fix) that drives the results sheet. Built against
/// the real `Simulation` engine (the S0 `MockSimulation` seam is retired now that the physics ships).
/// `@MainActor` because it feeds SwiftUI; `@Observable` so the canvas, HUD, banner and results sheet
/// redraw when its published state changes.
@MainActor
@Observable
final class SimulationController {
    /// The venue being simulated. Mutable because Apply & re-run swaps in RALLY's widened-exit venue.
    private(set) var venue: VenueModel
    private(set) var snapshot: SimulationSnapshot
    private(set) var isRunning = false

    /// Set the instant a run resolves; cleared on reset. Its presence drives the results sheet.
    private(set) var result: RunResult?
    /// The most recent live escalation while it is still "fresh" (raised within the last few seconds of
    /// sim time), or `nil` — the HUD banner shows this and nothing else.
    private(set) var escalation: EscalationTracker.Escalation?

    private var sim: Simulation
    private let config: SimulationConfig
    private var lastFrame: Date?
    /// The score to beat — the pre-fix run's score, carried across an Apply so the next result can show
    /// the before → after improvement. `nil` for a first run or a manual reset.
    private var baselineScore: Int?

    /// How long (sim seconds) an escalation banner stays up after it is raised.
    private let bannerLinger: TimeInterval = 4

    init(venue: VenueModel, config: SimulationConfig) {
        self.venue = venue
        self.config = config
        let engine = Simulation(venue: venue, config: config)
        sim = engine
        snapshot = engine.snapshot()
    }

    var isComplete: Bool { sim.isComplete }

    /// The RNG seed of the current run — persisted with a saved record for exact reproduction.
    var seed: UInt64 { config.seed }

    /// Start or resume. Clears the frame baseline so the first tick after resuming isn't a huge dt.
    func play() {
        guard !sim.isComplete else { return }
        lastFrame = nil
        isRunning = true
    }

    func pause() { isRunning = false }

    /// Rebuild from the same seed on the current venue — identical, reproducible playback. A manual
    /// reset forgets any before/after baseline; only an Apply sets one.
    func reset() {
        sim = Simulation(venue: venue, config: config)
        snapshot = sim.snapshot()
        escalation = nil
        result = nil
        baselineScore = nil
        lastFrame = nil
        isRunning = false
    }

    /// Apply RALLY's fix to the venue and re-run the identical crowd, remembering the score just earned
    /// so the next result renders "before → after". The core-journey payoff (§0.9).
    func applyFixAndRerun(_ fix: Fix) {
        let previous = result?.score.value
        venue = fix.apply(to: venue)
        reset()
        baselineScore = previous
        play()
    }

    /// Dismiss the results sheet without touching the finished run (the canvas keeps the final frame).
    func dismissResult() { result = nil }

    /// Advance to the wall-clock time of the current animation frame. Called once per display refresh
    /// from the canvas's `TimelineView`. `Simulation` clamps dt internally, so a dropped frame or a
    /// resume-after-pause can never blow the step up.
    func advance(to frame: Date) {
        guard isRunning, !sim.isComplete else { return }
        defer { lastFrame = frame }
        guard let previous = lastFrame else { return } // first frame only sets the baseline
        let dt = frame.timeIntervalSince(previous)
        guard dt > 0 else { return }
        sim.step(dt: dt)
        snapshot = sim.snapshot()
        refreshEscalation()
        if sim.isComplete {
            isRunning = false
            finish()
        }
    }

    /// Show the latest escalation only while it is fresh, so the banner appears on each crossing and
    /// clears itself a few seconds later rather than pinning the last one forever.
    private func refreshEscalation() {
        if let last = sim.escalations.last, snapshot.time - last.time < bannerLinger {
            escalation = last
        } else {
            escalation = nil
        }
    }

    /// Assemble the end-of-run analysis once, the moment the run resolves: score the metrics, run the
    /// verdict rules, and ask RALLY for a grounded fix. All pure engine calls.
    private func finish() {
        let metrics = sim.metrics
        let verdict = VerdictRules.default.evaluate(metrics)
        let score = SafetyScore(metrics: metrics)
        let fix = RallyCoach.default.suggest(for: verdict, metrics: metrics, in: venue)
        escalation = nil
        result = RunResult(
            venue: venue, metrics: metrics, verdict: verdict, score: score, fix: fix, baselineScore: baselineScore
        )
    }
}
