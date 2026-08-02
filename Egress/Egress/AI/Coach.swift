import EgressEngine
import Foundation

/// The rendered, ready-to-show coaching for one finished run — the value RALLY's results card displays.
/// Whether it came from the on-device Foundation model or the deterministic canned fallback, the card
/// renders it identically; only `source` differs (it drives the small provenance badge). Every number in
/// these strings is engine-sourced — the model only ever supplies phrasing, never figures (§3.5.2).
struct CoachAdvice: Equatable {
    /// Short, uppercase banner headline, e.g. "BOTTLENECK DETECTED" / "EVACUATION SUCCESSFUL".
    var headline: String
    /// The diagnosis (WARN/FAIL) or the success summary (PASS) — one or two sentences with real units.
    var body: String
    /// A supportive line (WARN/FAIL) or a safety-themed joke (PASS only), or `nil` if none.
    var closing: String?
    /// The deterministic engine fix the "Apply & re-run" button applies, or `nil` when the run passed or
    /// no feasible fix fits. The *action* is always engine-side; only its phrasing is ever AI-authored.
    var primaryFix: Fix?
    /// A second, lighter-touch suggestion shown as a caption (e.g. "Add a second exit"), or `nil`.
    var altSuggestion: String?
    var source: CoachSource
}

/// Where a piece of advice came from — the honesty label behind §3.5.4's "never presented as the
/// intended experience" rule: the canned fallback is a first-class asset, but it says so.
enum CoachSource: Equatable {
    /// The on-device Foundation model, every field validated against engine numbers (§3.5.3).
    case model
    /// Deterministic templated lines (Must tier) — used on any validation failure or unsupported device.
    case canned

    /// Provenance label for the card badge.
    var label: String {
        switch self {
        case .model: "On-device AI"
        case .canned: "RALLY"
        }
    }
}

/// A source of end-of-run coaching. Async because the on-device model streams; the canned coach returns
/// immediately. Deliberately non-throwing — a coach that cannot answer returns canned advice instead, so
/// the results card always has something grounded to show.
protocol Coach {
    func advise(for result: RunResult, venue: VenueModel) async -> CoachAdvice
}
