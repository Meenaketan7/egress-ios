import CoreHaptics
import Foundation
import UIKit

// MARK: - Haptics

/// The single haptic surface for the whole app (§5.5). Standard Taptic patterns go through
/// `UIFeedbackGenerator`; the **three** signature moments — the alarm klaxon, the crush swell and the
/// sombre FAIL — are hand-authored `CoreHaptics` patterns. Three is the entire custom scope by design:
/// enough for the moments that matter, small enough to test in a hackathon.
///
/// Everything routes through one `play(_:)` so the §5.5 global rules live in exactly one place: a
/// **1-per-0.5 s budget** (overflow dropped by priority, never queued), an **intensity cap** so only the
/// peaks reach 1.0, and the **Reduce Haptic Intensity** halving. If the hardware has no haptics — every
/// Simulator, and some devices — every call degrades silently to nothing, because each haptic event
/// already carries a sound and a visual twin (§5.5 rule 6). Nothing here is ever the sole channel.
@MainActor
final class Haptics {
    /// Every haptic the app can fire, named for the event rather than the pattern so callers stay
    /// declarative (`play(.verdictFail)`, not `play(.customPattern2)`).
    enum Event {
        // UI — budgeted, capped below peak.
        case toolTap, elementPlaced, invalidPlacement, deleteConfirmed, saved, rallyAppears
        // Score-ring reveal — self-limited to ≤8 ticks, so it bypasses the global budget.
        case scoreTick
        // Live escalations (§3.3) — first-crossing gated upstream.
        case congestion, bottleneck, crush, exitBlocked, casualty
        // Signature beats — never dropped, allowed to reach full intensity.
        case alarm, verdictPass, verdictWarn, verdictFail
    }

    init(settings: FeedbackSettings) {
        self.settings = settings
        prepareEngine()
    }

    /// Fire one haptic, subject to the §5.5 budget and intensity rules. Safe to call from anywhere on
    /// the main actor; a no-op when the hardware lacks haptics.
    func play(_ event: Event) {
        guard supportsHaptics else { return }             // §5.5 rule 5: degrade to sound + visual
        guard passesBudget(for: event) else { return }    // §5.5 rule 1: drop overflow by priority

        switch event {
        case .alarm: playCustom(klaxonPattern())
        case .crush: playCustom(crushPattern())
        case .verdictFail: playCustom(failPattern())

        case .toolTap: selection.selectionChanged()
        case .elementPlaced: impact(.light, intensity: cap)
        case .rallyAppears, .congestion: impact(.soft, intensity: cap)
        case .deleteConfirmed: impact(.rigid, intensity: cap)
        case .scoreTick: impact(.light, intensity: cap)
        case .casualty: impact(.heavy, intensity: peak)   // a casualty is a peak — full weight

        case .invalidPlacement, .bottleneck, .verdictWarn: notify(.warning)
        case .exitBlocked: notify(.error)
        case .saved, .verdictPass: notify(.success)
        }
    }

    /// Stop the engine (scene → background, §5.4). Restarted lazily before the next custom pattern.
    func stop() { engine?.stop() }

    // MARK: Budget & intensity (§5.5 rules 1–4)

    private let settings: FeedbackSettings
    private var lastPlay: Date = .distantPast
    private let minInterval: TimeInterval = 0.5

    /// Signature beats and casualties are never dropped; the self-limited score-tick sequence is exempt.
    /// Everything else must clear the 1-per-0.5 s window.
    private func passesBudget(for event: Event) -> Bool {
        switch event {
        case .alarm, .crush, .casualty, .verdictPass, .verdictWarn, .verdictFail, .scoreTick:
            return true
        default:
            let now = Date()
            guard now.timeIntervalSince(lastPlay) >= minInterval else { return false }
            lastPlay = now
            return true
        }
    }

    /// Non-peak intensity (rule 2: cap 0.7), halved under Reduce Haptic Intensity (rule 4).
    private var cap: CGFloat { settings.reduceHapticIntensity ? 0.35 : 0.7 }
    /// Peak intensity — casualty, crush and verdicts — halved under Reduce Haptic Intensity.
    private var peak: CGFloat { settings.reduceHapticIntensity ? 0.5 : 1.0 }

    // MARK: Standard generators

    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
    }

    // MARK: CoreHaptics engine (§5.4 restart discipline)

    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    /// Build the engine once, wiring the stopped/reset handlers that are the classic fix for "haptics
    /// died after a phone call" — both restart the engine so the next pattern still plays.
    private func prepareEngine() {
        guard supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.stoppedHandler = { [weak engine] _ in try? engine?.start() }
            engine.resetHandler = { [weak engine] in try? engine?.start() }
            self.engine = engine
        } catch {
            self.engine = nil // fall through to the sound + visual twins
        }
    }

    private func playCustom(_ pattern: CHHapticPattern?) {
        guard let engine, let pattern else { return }
        do {
            try engine.start()                    // lazy (re)start before every pattern
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            notify(.warning) // last-ditch standard fallback so a signature beat is still felt
        }
    }

    // MARK: The three custom patterns (§5.5)

    private func scaled(_ value: Float) -> Float { settings.reduceHapticIntensity ? value * 0.5 : value }

    /// `haptic.klaxon` — 2 sharp transients 0.18 s apart, repeated 3× over 1.2 s, synced to `sfx_klaxon`.
    private func klaxonPattern() -> CHHapticPattern? {
        var events: [CHHapticEvent] = []
        for repetition in 0 ..< 3 {
            let base = Double(repetition) * 0.4
            for offset in [0.0, 0.18] {
                events.append(transient(at: base + offset, intensity: scaled(1.0), sharpness: 0.9))
            }
        }
        return try? CHHapticPattern(events: events, parameters: [])
    }

    /// `haptic.crush` — a 0.9 s continuous swell ramping 0.4 → 1.0 at low sharpness (a rising dread, not
    /// a buzz). Under Reduce Haptic Intensity it collapses to a single soft transient (§5.5.4).
    private func crushPattern() -> CHHapticPattern? {
        if settings.reduceHapticIntensity {
            return try? CHHapticPattern(events: [transient(at: 0, intensity: 0.5, sharpness: 0.3)], parameters: [])
        }
        let swell = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                .init(parameterID: .hapticIntensity, value: 0.4),
                .init(parameterID: .hapticSharpness, value: 0.3),
            ],
            relativeTime: 0, duration: 0.9
        )
        let ramp = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [.init(relativeTime: 0, value: 0.4), .init(relativeTime: 0.9, value: 1.0)],
            relativeTime: 0
        )
        return try? CHHapticPattern(events: [swell], parameterCurves: [ramp])
    }

    /// `haptic.fail` — 2 low, soft transients at 0 s and 0.5 s. Deliberately *not* `.error`: a FAIL is
    /// sombre, not an alarm (§5.5).
    private func failPattern() -> CHHapticPattern? {
        try? CHHapticPattern(
            events: [
                transient(at: 0, intensity: scaled(0.7), sharpness: 0.2),
                transient(at: 0.5, intensity: scaled(0.7), sharpness: 0.2),
            ],
            parameters: []
        )
    }

    private func transient(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                .init(parameterID: .hapticIntensity, value: intensity),
                .init(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time
        )
    }
}
