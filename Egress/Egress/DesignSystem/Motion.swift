import SwiftUI

// MARK: - Motion

/// The single source of animation timing. Every spring in the app comes from here — no
/// ad-hoc `.spring(...)` values anywhere (design spec §6.1 / build plan §5.4). One token
/// set means the whole product moves with one personality.
enum Motion {
    /// Button and chip press, tool arm — snappy, no overshoot.
    static let tap = Animation.spring(response: 0.25, dampingFraction: 0.85)
    /// Config chips, density-chip expand — slight life.
    static let chip = Animation.spring(response: 0.30, dampingFraction: 0.80)
    /// Tool, results and settings sheets — system-like.
    static let sheet = Animation.spring(response: 0.45, dampingFraction: 0.85)
    /// Escalation banner in and out — urgent, not jarring.
    static let banner = Animation.spring(response: 0.35, dampingFraction: 0.75)
    /// RALLY entrance — visible overshoot; the mascot has personality.
    static let card = Animation.spring(response: 0.50, dampingFraction: 0.60)
    /// Emote badge pop-in ("?", "!"), scale 0.6 → 1.0 — tiny playful overshoot.
    static let emote = Animation.spring(response: 0.28, dampingFraction: 0.55)
    /// Any exit transition — critically damped; nothing bounces on the way out.
    static let dismiss = Animation.spring(response: 0.30, dampingFraction: 1.00)
    /// Tool-sheet detent change.
    static let toolSheet = Animation.spring(response: 0.40, dampingFraction: 0.85)

    // MARK: Not springs (§5.4)

    /// Score-ring reveal — a 1.2 s ease-out sweep with a synchronised count-up numeral,
    /// then `card` on the verdict badge.
    static let scoreRingReveal = Animation.easeOut(duration: scoreRingDuration)
    static let scoreRingDuration: TimeInterval = 1.2

    /// RALLY talk-loop frame rate, driven by `TimelineView(.periodic)` — runs only while
    /// text streams, stops on the last character.
    static let talkLoopFPS: Double = 8

    /// Ceiling on light haptic ticks during the score reveal, regardless of score
    /// (an 8-tick cap, not one tick per point).
    static let scoreRevealTickCeiling = 8
}
