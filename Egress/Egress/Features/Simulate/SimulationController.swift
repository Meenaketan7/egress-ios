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

    /// Smoothed display frame-rate shown in the HUD pill. An exponential moving average of the real
    /// frame cadence — this is a *rendering* readout, deliberately separate from the fixed 1/60
    /// simulation step, so it can honestly report a dropped frame without touching determinism.
    private(set) var fps: Double = 60

    /// A decimated tape of past frames (≈20 fps) so the transport can step back and the timeline can
    /// scrub. The engine is forward-only, so *reviewing* the past means replaying recorded snapshots;
    /// pressing play always resumes the real run from the live edge (`returnToLive`).
    private(set) var history: [SimulationSnapshot] = []
    /// The frame the canvas should draw: a recorded one while scrubbing, otherwise the live snapshot.
    private var seekIndex: Int?
    /// One recorded frame roughly every 1/20 s of sim time — enough to scrub smoothly without keeping
    /// every 1/60 step for a long run.
    private static let recordInterval: TimeInterval = 1.0 / 20.0
    private var lastRecordedTime: Double = -1

    /// Set the instant a run resolves; cleared on reset. Its presence drives the results sheet.
    private(set) var result: RunResult?
    /// The most recent live escalation while it is still "fresh" (raised within the last few seconds of
    /// sim time), or `nil` — the HUD banner shows this and nothing else.
    private(set) var escalation: EscalationTracker.Escalation?

    // MARK: Live camera (UI pan/zoom + tap-to-follow)

    /// The pan/zoom camera over the live canvas — reused from the editor, so the projection, gestures and
    /// hit-testing are the exact same maths. Pure UI state: it never touches the deterministic simulation.
    var camera = EditorCamera()
    /// One-time guard so the camera fits the whole venue the first time the view reports a real size.
    private(set) var cameraFramed = false
    /// The agent the camera is following (tap-to-focus), or `nil` for a free camera. While set, the camera
    /// re-centres on this person every frame so it tracks them as they move through the crowd.
    private(set) var focusedAgentID: Int?
    /// Last canvas size the view reported — lets the ± buttons and recenter anchor/fit without the view.
    private var lastViewSize: CGSize = .zero
    /// A comfortable "watch one person" zoom (points·m⁻¹) — a few metres across, big enough for the face.
    private static let focusZoom: CGFloat = 78

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
        recordFrame()
    }

    // MARK: Playback frame tape (step-back / scrub)

    /// The frame the canvas draws: the scrubbed history frame while seeking, else the live snapshot.
    var displaySnapshot: SimulationSnapshot {
        if let index = seekIndex, history.indices.contains(index) {
            return history[index]
        }
        return snapshot
    }

    /// Number of recorded frames — the timeline's scrub range.
    var frameCount: Int { history.count }

    /// The frame currently shown (its index into `history`): the scrub position, or the live edge.
    var displayIndex: Int { seekIndex ?? max(0, history.count - 1) }

    /// True while the transport is parked on a past frame rather than the live edge.
    var isScrubbing: Bool { seekIndex != nil }

    /// Sim-time of each escalation so far — the timeline draws a tick at each.
    var escalationTimes: [Double] { sim.escalations.map(\.time) }

    /// Total sim-time captured on the tape — the timeline's full-scale reference for placing ticks.
    var recordedDuration: Double { history.last?.time ?? snapshot.time }

    /// Append the current snapshot to the tape, decimated to `recordInterval` (the final frame always
    /// lands so a completed run scrubs to its true end).
    private func recordFrame() {
        let time = snapshot.time
        if history.isEmpty || time - lastRecordedTime >= Self.recordInterval || sim.isComplete {
            history.append(snapshot)
            lastRecordedTime = time
        }
    }

    /// Jump the scrubber to a recorded frame (pauses first — scrubbing never advances the real run).
    func seek(toIndex index: Int) {
        guard !history.isEmpty else { return }
        if isRunning { pause() }
        seekIndex = min(max(0, index), history.count - 1)
        updateFollowCamera()
    }

    /// Step one recorded frame back, pausing the run.
    func stepBack() {
        guard !history.isEmpty else { return }
        if isRunning { pause() }
        seekIndex = max(0, displayIndex - 1)
        updateFollowCamera()
    }

    /// Step forward one frame. While scrubbing this walks the tape (snapping back to live at the end);
    /// parked at the live edge it advances the real run one fixed 1/60 step.
    func stepForward() {
        if seekIndex != nil {
            let next = displayIndex + 1
            seekIndex = next >= history.count - 1 ? nil : next
            updateFollowCamera()
            return
        }
        guard !isRunning, !sim.isComplete else { return }
        sim.step(dt: Self.fixedStep)
        snapshot = sim.snapshot()
        refreshEscalation()
        recordFrame()
        updateFollowCamera()
        if sim.isComplete { finish() }
    }

    /// Return the transport to the live edge (the focus/recenter control) so the next play resumes the
    /// actual run rather than replaying history.
    func returnToLive() {
        seekIndex = nil
    }

    // MARK: Live camera — pan / zoom / tap-to-follow

    /// The venue's full extent in world metres — the "fit to floor" framing target.
    private var venueBounds: WorldRect {
        WorldRect(origin: .zero, size: Vec2(venue.geometry.worldWidth, venue.geometry.worldHeight))
    }

    /// The view reports its size each layout; the first real size frames the camera to the whole floor.
    func noteCanvasSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        lastViewSize = size
        if !cameraFramed {
            camera.fit(venueBounds, in: size)
            cameraFramed = true
        }
    }

    /// Zoom about the view centre — the ± buttons. `factor > 1` zooms in.
    func zoomCamera(by factor: CGFloat) {
        guard lastViewSize.width > 0 else { return }
        let projection = CanvasProjection(camera: camera, viewSize: lastViewSize)
        let centre = projection.world(CGPoint(x: lastViewSize.width / 2, y: lastViewSize.height / 2))
        camera.zoom(by: factor, aroundWorld: centre)
    }

    /// Fit the whole floor and stop following anyone — the canvas "recenter".
    func recenterCamera() {
        focusedAgentID = nil
        guard lastViewSize.width > 0 else { return }
        camera.fit(venueBounds, in: lastViewSize)
        cameraFramed = true
    }

    /// A free-camera pan (a finger drag) — drops any follow so the drag isn't fought each frame.
    func panCamera(byScreen delta: CGSize) {
        focusedAgentID = nil
        camera.pan(byScreen: delta)
    }

    /// Pinch-zoom about a world anchor (the pinch centroid). Keeps any follow so you can zoom on a tracked
    /// person; the follow just re-centres them next frame.
    func pinchCamera(by factor: CGFloat, aroundWorld anchor: Vec2) {
        camera.zoom(by: factor, aroundWorld: anchor)
    }

    /// Tap-to-focus: pick the nearest active agent to a tapped world point and follow it, zoomed in enough
    /// to read its face. A tap on empty floor (nothing within reach) drops the follow instead.
    func focusAgent(nearWorld world: Vec2) {
        let hitRadius = 1.2 // metres — a generous finger target in world space
        let nearest = displaySnapshot.agents
            .filter(\.status.isActive)
            .min { $0.position.distance(to: world) < $1.position.distance(to: world) }
        guard let agent = nearest, agent.position.distance(to: world) <= hitRadius else {
            focusedAgentID = nil
            return
        }
        focusedAgentID = agent.id
        camera.pointsPerMetre = EditorCamera.clampZoom(max(camera.pointsPerMetre, Self.focusZoom))
        camera.center = agent.position
    }

    /// Re-centre on the followed agent for the current frame; clears the follow once they leave the floor.
    private func updateFollowCamera() {
        guard let id = focusedAgentID else { return }
        if let agent = displaySnapshot.agents.first(where: { $0.id == id && $0.status.isActive }) {
            camera.center = agent.position
        } else {
            focusedAgentID = nil
        }
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
        seekIndex = nil // resume from the live edge, never from a scrubbed-back frame
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
        history = []
        seekIndex = nil
        lastRecordedTime = -1
        focusedAgentID = nil // the crowd respawns — don't chase a stale identity; keep the user's zoom
        recordFrame()
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

        // Smooth the observed frame rate for the HUD (0.1 EMA); clamp so a huge post-stall dt can't
        // print an absurd number. Purely cosmetic — it never feeds the fixed-step accumulator below.
        let instantaneous = min(120, 1.0 / elapsed)
        fps = fps * 0.9 + instantaneous * 0.1

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
        recordFrame()
        updateFollowCamera()
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
