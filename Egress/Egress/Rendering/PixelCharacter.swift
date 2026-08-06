import EgressEngine
import SwiftUI

// MARK: - PixelCharacter

/// One animated pixel person for chrome — the character standing on a preset card, or a walker in the
/// landing diorama. Wraps `AgentSprites.drawHero` in a `TimelineView` so it idles (a gentle bob) or
/// walks in place, and holds a still frame under Reduce Motion. It's the *same* sprite system the live
/// crowd draws with, so the person on a card is the person a run will spawn.
struct PixelCharacter: View {
    var mobility: MobilityClass
    var emotion: EmotionalState = .calm
    /// Stable per-character seed — decides skin, hair and clothing, exactly as it does in a run.
    var seed: Int
    var walking: Bool = false
    var mirrored: Bool = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let phase = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                AgentSprites.drawHero(
                    mobility: mobility,
                    emotion: emotion,
                    seed: seed,
                    walking: walking && !reduceMotion,
                    mirrored: mirrored,
                    phase: phase,
                    // Inset leaves headroom for a panic pose and keeps the feet off the very edge.
                    in: CGRect(origin: .zero, size: size).insetBy(dx: size.width * 0.08, dy: size.height * 0.07),
                    into: &context
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Stable seeds

extension String {
    /// A process-independent hash for choosing a character's look from a preset id — unlike
    /// `hashValue`, this is stable across launches so a card's person doesn't re-roll each run.
    var pixelSeed: Int {
        var h = 1_469_598_103_934_665_603 as UInt64 // FNV-1a
        for byte in utf8 { h = (h ^ UInt64(byte)) &* 1_099_511_628_211 }
        return Int(truncatingIfNeeded: h) & 0x7FFF_FFFF
    }
}
