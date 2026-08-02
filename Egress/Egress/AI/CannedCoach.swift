import EgressEngine
import Foundation

/// The deterministic templated coach (§3.5.4) — RALLY with **zero** AI. It reads the finished run's
/// verdict and metrics and fills a template with engine numbers, so the app is fully coherent and
/// demoable on any device. This is a scored Must-tier asset, not just a contingency: on an unsupported
/// device, or whenever the on-device model's output fails a validation check, this is what speaks.
struct CannedCoach: Coach {
    func advise(for result: RunResult, venue: VenueModel) async -> CoachAdvice {
        let facts = CoachFacts(result: result, venue: venue)

        if result.verdict.level == .pass {
            return CoachAdvice(
                headline: "EVACUATION SUCCESSFUL",
                body: "Everyone cleared in \(facts.clearance) s, peak density \(facts.peakDensityText). "
                    + "Comfortably under the \(facts.target) s target for a \(venue.type.displayName.lowercased()).",
                closing: Self.joke(for: facts),
                primaryFix: nil,
                altSuggestion: nil,
                source: .canned
            )
        }

        // WARN / FAIL — lead with the violated threshold (§3.2), keyed off the level-setting reason.
        let leading = result.verdict.reasons.first?.metricKey
        let (headline, body) = Self.diagnosis(for: leading, facts: facts, venue: venue)
        return CoachAdvice(
            headline: headline,
            body: body,
            closing: Self.encouragement(for: facts),
            primaryFix: result.fix,
            altSuggestion: Self.altSuggestion(for: leading),
            source: .canned
        )
    }

    // MARK: Templates

    /// Headline + number-filled body for the level-setting reason (§3.5.4 table).
    private static func diagnosis(
        for key: MetricKey?, facts: CoachFacts, venue: VenueModel
    ) -> (String, String) {
        switch key {
        case .casualties:
            return ("EVACUATION FAILED",
                    "\(facts.casualties) did not make it out \(facts.peakLocation). The route has to stay clear of the hazard.")
        case .occupantsTrapped:
            return ("OCCUPANTS TRAPPED",
                    "\(facts.trapped) of \(facts.occupancy) couldn't reach an exit within the \(facts.cap) s cap — the floor can't drain fast enough.")
        case .peakDensity:
            return ("BOTTLENECK DETECTED",
                    "Peak density reached \(facts.peakDensityText) \(facts.peakLocation) — above the \(facts.cautionBandText) caution band.")
        case .clearance:
            return ("TOO SLOW",
                    "Clearance took \(facts.clearance) s, past the \(facts.target) s target for a \(venue.type.displayName.lowercased()).")
        case .atRiskFraction:
            return ("CROWD UNDER PRESSURE",
                    "\(facts.atRiskPct)% of the crowd spent over \(facts.dwell) s above the \(facts.cautionBandText) caution band.")
        case .safetyScore, .none:
            return ("NEEDS WORK",
                    "This layout scored \(facts.score) — below the pass mark. The crowd is meeting more resistance than it should.")
        }
    }

    /// The lighter second suggestion, when the primary fix isn't the whole story.
    private static func altSuggestion(for key: MetricKey?) -> String? {
        switch key {
        case .peakDensity, .clearance, .occupantsTrapped: "Or add a second exit to split the flow."
        case .atRiskFraction: "Or relocate furniture to open the route."
        case .casualties: "Or move the exit away from the hazard."
        default: nil
        }
    }

    // MARK: Voice — deterministic so a re-shown card never changes wording mid-demo.

    private static let encouragements = [
        "A small change to the geometry here can make a real difference.",
        "You've found the weak point — now let's open it up.",
        "Good news: this is a layout problem, and layout problems are fixable."
    ]

    private static func encouragement(for facts: CoachFacts) -> String {
        encouragements[abs(facts.clearance) % encouragements.count]
    }

    /// Safety-themed, never about injury — the canned mirror of the PASS-only `joke` field (§3.5.1).
    private static let jokes = [
        "I'd tell you a fire-drill joke, but you'd all see it coming.",
        "Smooth exit. The only bottleneck left is the coffee machine.",
        "Textbook flow — even the fire marshal would crack a smile."
    ]

    private static func joke(for facts: CoachFacts) -> String {
        jokes[abs(facts.clearance) % jokes.count]
    }
}
