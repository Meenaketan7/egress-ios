import EgressEngine
import SwiftData
import SwiftUI

/// Simulate tab entry — wraps the shared `SimulateScreen` in its own navigation stack with the stock
/// demo venue. The editor pushes `SimulateScreen(venue:config:)` into an existing stack instead, so
/// the screen itself carries no `NavigationStack` of its own.
struct SimulateRootView: View {
    var body: some View {
        NavigationStack {
            SimulateScreen()
        }
    }
}

/// Simulation host — owns the run and shows the live canvas, HUD, escalation banner and transport
/// controls, then the results sheet the moment the run resolves (§0.9 core journey). Reusable: the
/// Simulate tab shows the demo venue; the editor hands in a user-authored venue + crowd.
struct SimulateScreen: View {
    @Environment(\.modelContext) private var modelContext
    /// Optional so SwiftUI previews that don't inject the feedback root still render (they simply run silent).
    @Environment(FeedbackServices.self) private var feedback: FeedbackServices?
    /// Data-motion stays; decorative motion (the banner spring) softens to a cross-fade (§5.6).
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var controller: SimulationController
    @State private var showSettings = false
    /// Last VoiceOver announcement time — escalation/verdict announcements stay ≥4 s apart (§5.6).
    @State private var lastAnnouncement: Date = .distantPast

    init(
        venue: VenueModel = SampleVenue.crowdedClub(),
        config: SimulationConfig = SimulationConfig(agentCount: 170, maxValidatedAgents: 300, seed: 42)
    ) {
        _controller = State(initialValue: SimulationController(venue: venue, config: config))
    }

    var body: some View {
        CanvasHost {
            VStack(spacing: EgressSpacing.md) {
                SimCanvasView(controller: controller)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .top) {
                        if let escalation = controller.escalation {
                            EscalationBanner(escalation: escalation)
                                .padding(EgressSpacing.md)
                        }
                    }
                    .animation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.banner, value: controller.escalation)

                hud
                controls
            }
            .padding(EgressSpacing.md)
        }
        .navigationTitle(controller.venue.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: { Image(app: .settings) }
                    .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showSettings) { SettingsSheet() }
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
                    onRunAgain: { controller.reset(); controller.play() },
                    onDone: { controller.dismissResult() }
                )
            }
        }
    }

    /// Drives the results sheet off the controller's `result`; dismissing clears it.
    private var resultPresented: Binding<Bool> {
        Binding(
            get: { controller.result != nil },
            set: { if !$0 { controller.dismissResult() } }
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
        if throttled, now.timeIntervalSince(lastAnnouncement) < 4 { return }
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
                Label(controller.isRunning ? "Pause" : "Play",
                      systemImage: controller.isRunning ? "pause.fill" : "play.fill")
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
