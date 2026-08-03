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
    /// Wall-clock time observed but not yet discharged as whole fixed steps (§3, determinism fix).
    private var stepAccumulator: TimeInterval = 0
    /// The score to beat — the pre-fix run's score, carried across an Apply so the next result can show
    /// the before → after improvement. `nil` for a first run or a manual reset.
    private var baselineScore: Int?
    /// The pre-fix run's casualty count, carried across an Apply so the next result can show lives saved.
    private var baselineCasualties: Int?

    /// The fixed simulation timestep the app feeds the engine — **identical to the test driver's**
    /// `step(dt: 1/60)`. The engine substeps physics at H = 1/120 internally, but hazards, emotions,
    /// metrics and escalation are each sampled *once per `step` call*, so a variable real-frame dt would
    /// drift those samples off the deterministic run. Feeding a fixed dt makes the same seed clear in the
    /// same time in-app as in tests — the S2 criterion-6 (reproducibility) prerequisite.
    static let fixedStep: TimeInterval = 1.0 / 60.0
    /// The most fixed steps one display frame may discharge. A long stall (backgrounding, a slow frame)
    /// banks at most this much catch-up; the rest is dropped, so playback can never enter a spiral of
    /// death. Dropping backlog changes *when* steps run, never any step's dt — so the outcome stays
    /// deterministic (completion still takes the same total number of 1/60 steps).
    private static let maxStepsPerFrame = 8

    /// How long (sim seconds) an escalation banner stays up after it is raised.
    private let bannerLinger: TimeInterval = 4

    init(venue: VenueModel, config: SimulationConfig) {
        self.venue = venue
        self.config = config
        let engine = Simulation(venue: venue, config: config)
        sim = engine
        snapshot = engine.snapshot()
    }

    var isComplete: Bool {
        sim.isComplete
    }

    /// Whether this run carries more agents than the validated performance budget (§E.2) — drives the
    /// quiet "above budget" step-down notice.
    var isAboveBudget: Bool {
        config.isAboveBudget
    }

    /// The configured crowd size and the validated performance budget it's measured against (§E.2 notice).
    var configuredAgents: Int {
        config.agentCount
    }

    var validatedBudget: Int {
        config.maxValidatedAgents
    }

    /// The RNG seed of the current run — persisted with a saved record for exact reproduction.
    var seed: UInt64 {
        config.seed
    }

    /// Start or resume. Clears the frame baseline and the step backlog so the first tick after resuming
    /// isn't a huge dt and no stale catch-up is banked across a pause.
    func play() {
        guard !sim.isComplete else { return }
        lastFrame = nil
        stepAccumulator = 0
        isRunning = true
    }

    func pause() {
        isRunning = false
    }

    /// Rebuild from the same seed on the current venue — identical, reproducible playback. A manual
    /// reset forgets any before/after baseline; only an Apply sets one.
    func reset() {
        sim = Simulation(venue: venue, config: config)
        snapshot = sim.snapshot()
        escalation = nil
        result = nil
        baselineScore = nil
        baselineCasualties = nil
        lastFrame = nil
        stepAccumulator = 0
        isRunning = false
    }

    /// Apply RALLY's fix to the venue and re-run the identical crowd, remembering the score just earned
    /// so the next result renders "before → after". The core-journey payoff (§0.9).
    func applyFixAndRerun(_ fix: Fix) {
        let previousScore = result?.score.value
        let previousCasualties = result?.metrics.casualties
        venue = fix.apply(to: venue)
        reset()
        baselineScore = previousScore
        baselineCasualties = previousCasualties
        play()
    }

    /// Dismiss the results sheet without touching the finished run (the canvas keeps the final frame).
    func dismissResult() {
        result = nil
    }

    /// Advance to the wall-clock time of the current animation frame. Called once per display refresh
    /// from the canvas's `TimelineView`. Rather than pass the raw frame dt to the engine (which would
    /// make each `step` sample hazards/emotions/metrics at a drifting interval), we bank the elapsed
    /// wall-clock time and discharge it in **fixed 1/60 steps** — exactly how the test suite drives the
    /// engine. So the same seed clears in the same time in-app as in tests (S2 determinism).
    func advance(to frame: Date) {
        guard isRunning, !sim.isComplete else { return }
        defer { lastFrame = frame }
        guard let previous = lastFrame else { return } // first frame only sets the baseline
        let elapsed = frame.timeIntervalSince(previous)
        guard elapsed > 0 else { return }

        stepAccumulator += elapsed
        var steps = 0
        while stepAccumulator >= Self.fixedStep, steps < Self.maxStepsPerFrame, !sim.isComplete {
            sim.step(dt: Self.fixedStep)
            stepAccumulator -= Self.fixedStep
            steps += 1
        }
        // A frame that fell further behind than the catch-up budget drops its backlog rather than
        // banking it — playback stays real-time and can never runaway.
        if stepAccumulator > Self.fixedStep {
            stepAccumulator = 0
        }

        guard steps > 0 else { return } // sub-frame gap: nothing advanced, nothing to redraw
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
            venue: venue,
            metrics: metrics,
            verdict: verdict,
            score: score,
            fix: fix,
            baselineScore: baselineScore,
            baselineCasualties: baselineCasualties
        )
    }
}
