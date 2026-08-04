import EgressEngine
import SwiftData
import SwiftUI

// MARK: - SimulateRootView

/// Simulate tab entry — owns the tab's own load lifecycle (§E.2): an explicit **empty** first-launch, a
/// route-solve **loading** warm-up, then the live `SimulateScreen`. The editor pushes
/// `SimulateScreen(venue:config:)` into its own stack instead and bypasses this — it always arrives with
/// a venue already in hand.
struct SimulateRootView: View {
    @State private var phase: LoadPhase = .empty

    private enum LoadPhase {
        case empty
        case loading(Double)
        case ready(VenueModel, SimulationConfig)
    }

    var body: some View {
        NavigationStack {
            content
        }
    }

    @ViewBuilder private var content: some View {
        switch phase {
        case .empty:
            CanvasHost { SimulateEmptyState(onLoadDemo: loadDemo) }
                .navigationTitle("Simulate")
                .navigationBarTitleDisplayMode(.inline)
        case let .loading(progress):
            CanvasHost { SimulateLoadingState(progress: progress) }
                .navigationTitle("Simulate")
                .navigationBarTitleDisplayMode(.inline)
        case let .ready(venue, config):
            SimulateScreen(venue: venue, config: config)
        }
    }

    /// Load the demo scenario through a genuine route-solve warm-up: constructing the engine builds the
    /// flow field and spawns the crowd (the real work), so the first rendered frame is never a frozen
    /// canvas. The determinate indicator is paced briefly so the state stays legible in the recording.
    private func loadDemo() {
        let (venue, config) = SampleVenue.moneyShotDemo()
        phase = .loading(0.15)
        Task { @MainActor in
            phase = .loading(0.5)
            _ = Simulation(venue: venue, config: config) // real flow-field solve + spawn
            try? await Task.sleep(for: .milliseconds(350))
            phase = .loading(1.0)
            try? await Task.sleep(for: .milliseconds(140))
            phase = .ready(venue, config)
        }
    }
}

// MARK: - SimulateScreen

/// Simulation host — owns the run and shows the live canvas, HUD, escalation banner and transport
/// controls, then the results sheet the moment the run resolves (§0.9 core journey). Reusable: the
/// Simulate tab shows the demo venue; the editor hands in a user-authored venue + crowd.
struct SimulateScreen: View {
    @Environment(\.modelContext)
    private var modelContext
    /// Optional so SwiftUI previews that don't inject the feedback root still render (they simply run silent).
    @Environment(FeedbackServices.self)
    private var feedback: FeedbackServices?
    /// Data-motion stays; decorative motion (the banner spring) softens to a cross-fade (§5.6).
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    /// Drives the return-from-background pause (§E.2) — a run is never advanced while the app is away.
    @Environment(\.scenePhase)
    private var scenePhase

    @State private var controller: SimulationController
    @State private var showSettings = false
    /// Set when a running sim is held on the way to the background; a return shows `PAUSED`, no auto-resume.
    @State private var pausedOnReturn = false
    /// Latest device thermal state — a `.serious`/`.critical` reading raises the step-down notice (§E.2).
    @State private var thermalState = ProcessInfo.processInfo.thermalState
    /// Last VoiceOver announcement time — escalation/verdict announcements stay ≥4 s apart (§5.6).
    @State private var lastAnnouncement: Date = .distantPast

    init(
        venue: VenueModel = SampleVenue.crowdedClub(),
        config: SimulationConfig = SimulationConfig(agentCount: 170, maxValidatedAgents: 300, seed: 42)
    ) {
        _controller = State(initialValue: SimulationController(venue: venue, config: config))
    }

    var body: some View {
        // The dark game-screen is framed in cream: only the canvas stays dark so agents, density and
        // hazards read; the HUD, banner and controls take the friendly cream shell (design hero).
        VStack(spacing: EgressSpacing.md) {
            CanvasHost {
                SimCanvasView(controller: controller, patternFills: feedback?.settings.colorBlindPatterns ?? true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .top) {
                        if let escalation = controller.escalation {
                            EscalationBanner(escalation: escalation)
                                .padding(EgressSpacing.md)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if let notice = performanceNotice {
                            PerformanceNotice(kind: notice).padding(EgressSpacing.sm)
                        }
                    }
                    .overlay {
                        if pausedOnReturn {
                            PausedOnReturnPanel(onResume: resumeAfterReturn)
                                .transition(.opacity)
                        }
                    }
                    .animation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.banner, value: controller.escalation)
            }
            .clipShape(RoundedRectangle.egSquircle(EgressRadius.lg))
            .overlay(
                RoundedRectangle.egSquircle(EgressRadius.lg)
                    .strokeBorder(Color.egOutline, lineWidth: 2)
            )

            hud
            controls
        }
        .padding(EgressSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.egGround)
        .navigationTitle(controller.venue.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: { Image(app: .settings) }
                    .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showSettings) { SettingsSheet() }
        .onChange(of: scenePhase) { _, phase in handleScenePhase(phase) }
        .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)) { _ in
            thermalState = ProcessInfo.processInfo.thermalState
        }
        .onChange(of: escalationKey) { _, _ in announceEscalation() }
        .onChange(of: controller.result?.id) { _, id in
            if id != nil {
                persistLatestRun()
                announceVerdict()
            }
        }
        .sheet(isPresented: resultPresented) {
            if let result = controller.result {
                ResultsSheet(
                    result: result,
                    onApply: { controller.applyFixAndRerun($0) },
                    onRunAgain: { controller.reset()
                        controller.play()
                    },
                    onDone: { controller.dismissResult() }
                )
            }
        }
    }

    /// Drives the results sheet off the controller's `result`; dismissing clears it.
    private var resultPresented: Binding<Bool> {
        Binding(
            get: { controller.result != nil },
            set: {
                if !$0 {
                    controller.dismissResult()
                }
            }
        )
    }

    /// Save the just-resolved run to the local SwiftData store — the Spaces history and run record (§3.6).
    private func persistLatestRun() {
        guard let result = controller.result else { return }
        let record = RunRecord(
            venueName: controller.venue.name,
            venueTypeRaw: controller.venue.type.rawValue,
            score: result.score.value,
            verdictRaw: result.verdict.level.rawValue,
            clearanceTime: result.metrics.clearance,
            occupancy: result.metrics.spawnedCount,
            seed: String(controller.seed)
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    // MARK: States & recovery (§E.2)

    /// Hold a running sim when the app leaves the foreground and never auto-resume on return — the run is
    /// only advanced while it's being watched. Coming back raises the `PAUSED` panel.
    private func handleScenePhase(_ phase: ScenePhase) {
        // Only a true background trip holds the run — transient `.inactive` (Control Center, a banner)
        // must not force a manual resume mid-demo.
        guard phase == .background, controller.isRunning else { return }
        controller.pause()
        pausedOnReturn = true
    }

    /// Explicit resume from the `PAUSED` panel — the only way a backgrounded run continues.
    private func resumeAfterReturn() {
        pausedOnReturn = false
        controller.play()
    }

    /// The single performance step-down notice to show, if any (§E.2 failure/recovery). A hot device takes
    /// precedence over the above-budget line; neither shows once the run has resolved.
    private var performanceNotice: PerformanceNotice.Kind? {
        guard controller.result == nil else { return nil }
        switch thermalState {
        case .serious: return .thermal("serious")
        case .critical: return .thermal("critical")
        default:
            return controller.isAboveBudget
                ? .aboveBudget(agents: controller.configuredAgents, budget: controller.validatedBudget)
                : nil
        }
    }

    // MARK: Feedback (§5.5) + VoiceOver announcements (§5.6)

    /// Identity that changes on each new live escalation, so `.onChange` fires once per crossing.
    private var escalationKey: String? {
        controller.escalation.map { "\($0.band)-\($0.time)" }
    }

    /// Start or pause. A fresh start *is* the emergency alarm — klaxon sound + custom haptic (§5.5).
    private func togglePlay() {
        if controller.isRunning {
            controller.pause()
        } else {
            if controller.snapshot.live.elapsed == 0 {
                feedback?.sound.play(.klaxon)
                feedback?.haptics.play(.alarm)
            }
            controller.play()
        }
    }

    /// A new live band crossed: the sting, the band-specific haptic, and a throttled announcement.
    private func announceEscalation() {
        guard let escalation = controller.escalation else { return }
        feedback?.sound.play(.sting)
        switch escalation.band {
        case .congestion: feedback?.haptics.play(.congestion)
        case .bottleneck: feedback?.haptics.play(.bottleneck)
        case .crush: feedback?.haptics.play(.crush)
        case .exitBlocked: feedback?.haptics.play(.exitBlocked)
        case .casualty: feedback?.haptics.play(.casualty)
        }
        announce(escalation.band.headline, throttled: true)
    }

    /// The end-of-run verdict announcement — posted immediately so a VoiceOver user hears the outcome
    /// as the sheet appears. It always posts (§5.6 priority: a verdict pre-empts a lingering escalation).
    /// The verdict *sound* and *haptic* fire in `ResultsSheet`, synced to the end of the score-ring
    /// reveal, so the felt/heard payoff lands with the final number.
    private func announceVerdict() {
        guard let result = controller.result else { return }
        announce("\(result.verdict.level.label). Safety score \(result.score.value) out of 100.", throttled: false)
    }

    /// Post a VoiceOver announcement. Escalations are throttled to ≥4 s apart so a busy run doesn't
    /// chatter; the verdict overrides the throttle.
    private func announce(_ message: String, throttled: Bool) {
        let now = Date()
        if throttled, now.timeIntervalSince(lastAnnouncement) < 4 {
            return
        }
        lastAnnouncement = now
        AccessibilityNotification.Announcement(message).post()
    }

    private var hud: some View {
        HStack(spacing: EgressSpacing.xl) {
            metric("Inside", "\(controller.snapshot.live.activeCount)", .egDataGreen)
            metric("Elapsed", String(format: "%.1fs", controller.snapshot.live.elapsed), .egTextPrimary)
            metric("Density", String(format: "%.1f", controller.snapshot.live.worstDensity), .egCyan)
            metric("Out", String(format: "%.0f%%", controller.snapshot.live.fractionOut * 100), .egCyan)
        }
        .padding(EgressSpacing.md)
        .frame(maxWidth: .infinity)
        .egGlassSurface()
    }

    private func metric(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: EgressSpacing.xxs) {
            Text(label).egMicroLabel()
            Text(value).egData(.title2).foregroundStyle(tint)
        }
    }

    private var controls: some View {
        HStack(spacing: EgressSpacing.md) {
            Button(action: togglePlay) {
                Label(
                    controller.isRunning ? "Pause" : "Play",
                    systemImage: controller.isRunning ? "pause.fill" : "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(controller.isComplete)
            .accessibilityHint(controller.isRunning ? "Pauses the evacuation" : "Sounds the alarm and starts the evacuation")

            Button {
                controller.reset()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Restarts the same crowd from the beginning")
        }
        .tint(.egDataGreen)
    }
}

#Preview {
    SimulateRootView()
}
