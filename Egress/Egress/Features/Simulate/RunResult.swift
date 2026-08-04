import EgressEngine
import Foundation

/// The end-of-run analysis the results sheet and RALLY card read, bundled so the sheet takes one value.
/// Assembled by `SimulationController` the moment a run resolves — pure engine output (Metrics → Verdict
/// + Safety Score + a grounded RALLY fix), nothing UI-specific.
struct RunResult: Identifiable, Equatable {
    let id = UUID()
    /// The venue this run was computed on (post-Apply it's the widened one) — so the coach can cite its
    /// exits and props without the sheet having to reach back into the controller.
    let venue: VenueModel
    let metrics: Metrics
    let verdict: Verdict
    let score: SafetyScore
    /// RALLY's single grounded geometry fix for a run that fell short, or `nil` when the run passed or no
    /// feasible fix fits — the presence of a fix is what offers the Apply & re-run button.
    let fix: Fix?
    /// The score of the run this one is measured against (the pre-fix run), or `nil` for a first run —
    /// drives the "before → after" delta after an Apply.
    let baselineScore: Int?
    /// Casualties in the pre-fix run, carried across an Apply. With a fire scenario the Safety Score's
    /// casualty term saturates, so the score barely moves even as deaths fall — this makes the fix's real
    /// impact (fewer casualties) visible in its own right.
    var baselineCasualties: Int?

    /// The point improvement over the baseline run, when this result followed an Apply.
    var improvement: Int? {
        baselineScore.map { score.value - $0 }
    }

    /// How many fewer people were hurt after the fix (positive = lives saved), when this run followed an
    /// Apply and either run involved casualties.
    var casualtiesAverted: Int? {
        guard let before = baselineCasualties, before > 0 || metrics.casualties > 0 else { return nil }
        return before - metrics.casualties
    }
}
