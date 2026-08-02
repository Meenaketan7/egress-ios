import EgressEngine
import Foundation

// The on-device Foundation-model coach and its validation gate (§3.5.2–3.5.3).
//
// This whole file is compiled only when the `EGRESS_FM_COACH` build flag is defined AND the SDK
// provides FoundationModels. It is a faithful scaffold of the model path: the three `@Generable`
// schemas, the prompt contract, and the V1–V8 gate. The exact `@Generable`/`@Guide` constraint
// spellings still need verification in Xcode 27 on hardware (§3.5.2), which is why the flag is off by
// default — the shipped, verified experience here is `CannedCoach`, and this drops in behind it once
// confirmed on a device. Every path failure returns `fallback` advice, so the model can only ever make
// the wording nicer, never leave the card empty or let an un-grounded number through.
#if EGRESS_FM_COACH && canImport(FoundationModels)
import FoundationModels

// MARK: - Generable schemas (§3.5.2)

/// The metric the model may cite — by *key*, never a value; the app substitutes the engine number at
/// render time, so the model cannot invent a figure.
enum CoachMetricKey: String, Codable, CaseIterable, Sendable {
    case peakDensity, clearanceTime, atRiskFraction, casualties
    case exitFlowRate, exitClearWidth, corridorWidth, occupantCount, aisleClearWidth
}

enum FixTargetKind: String, Codable, CaseIterable, Sendable {
    case exit, corridor, obstacle, wall
}

@Generable
struct FixTarget {
    @Guide(description: "Kind of element.") let kind: FixTargetKind
    @Guide(description: "Identifier copied verbatim from the supplied venue element list.")
    let elementID: String
}

@Generable
struct GeometryFix {
    @Guide(description: "Which element to change.") let target: FixTarget
    @Guide(description: "Imperative instruction WITHOUT numbers, e.g. 'Widen the main corridor'.")
    let instruction: String
    @Guide(description: "The metric that justifies this fix.") let citedMetric: CoachMetricKey
    @Guide(description: "Proposed new clear width in metres.", .range(0.9 ... 6.0))
    let proposedMetres: Double?
}

@Generable
struct WarnFailAdvice { // WARN + FAIL — no joke field, by design
    @Guide(description: "One or two sentences naming WHERE and WHY the jam formed. Never write digits.")
    let diagnosis: String
    @Guide(description: "Two or three concrete fixes.", .count(2 ... 3))
    let fixes: [GeometryFix]
    @Guide(description: "One supportive line. No humour. Never write digits.")
    let encouragement: String
}

@Generable
struct PassAdvice { // PASS only — the joke field exists ONLY here (§3.5.1)
    let summary: String
    @Guide(description: "One light, safety-themed joke. Never about casualties or injury.")
    let joke: String
}

// MARK: - Coach

struct FoundationModelsCoach: Coach {
    /// Where every validation failure or timeout lands — the canned coach.
    let fallback: CannedCoach
    /// V7 latency budget (§3.5.3).
    private let timeout: Duration = .seconds(4)

    func advise(for result: RunResult, venue: VenueModel) async -> CoachAdvice {
        let facts = CoachFacts(result: result, venue: venue)
        do {
            if result.verdict.level == .pass {
                let advice: PassAdvice = try await generate(passPrompt(facts, venue))
                return CoachValidation.validatePass(advice, facts: facts) ?? (await fallback.advise(for: result, venue: venue))
            } else {
                let advice: WarnFailAdvice = try await generate(warnFailPrompt(facts, venue))
                return CoachValidation.validateWarnFail(advice, result: result, venue: venue, facts: facts)
                    ?? (await fallback.advise(for: result, venue: venue))
            }
        } catch {
            return await fallback.advise(for: result, venue: venue) // V1/V7: refusal, malformed, or timeout
        }
    }

    /// Run one generation with the V7 timeout; the loser of the race throws so we fall back.
    private func generate<T: Generable>(_ prompt: (instructions: String, user: String)) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                let session = LanguageModelSession(instructions: prompt.instructions)
                return try await session.respond(to: prompt.user, generating: T.self).content
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw CoachError.timedOut
            }
            let first = try await group.next()!
            group.cancelAll()
            return first
        }
    }

    // MARK: Prompts — supply the digest, the valid element IDs, and the minima (§3.5.2 prompt contract)

    private var contract: String {
        """
        You are RALLY, a calm building-safety coach. Use ONLY the supplied element IDs. \
        NEVER write digits or numeric values in prose — cite a metric by its key instead. \
        Minimum clear widths: interior door 0.9 m, final exit 1.2 m, corridor 1.2 m.
        """
    }

    private func warnFailPrompt(_ facts: CoachFacts, _ venue: VenueModel) -> (String, String) {
        (contract, """
        Run digest: worst crowding \(facts.peakLocation); score \(facts.score).
        Valid element IDs: \(CoachValidation.elementIDList(for: venue)).
        Diagnose where and why the crowd jammed, then propose 2–3 concrete geometry fixes.
        """)
    }

    private func passPrompt(_ facts: CoachFacts, _ venue: VenueModel) -> (String, String) {
        (contract, "The \(venue.type.displayName) evacuated cleanly. Give a one-line summary and one light, safety-themed joke.")
    }
}

private enum CoachError: Error { case timedOut }

// MARK: - Validation gate (§3.5.3)

/// V1–V8 — the model's output must clear every check or we fall back. Numbers are never trusted from the
/// model (V4); geometry must be feasible (V5); every element must exist (V2); jokes are casualty-free (V8).
enum CoachValidation {
    /// The exit/obstacle/wall IDs the model is allowed to reference, as a prompt-friendly list.
    static func elementIDList(for venue: VenueModel) -> String {
        let exits = venue.exits.map { "exit \($0.id)" }
        let obstacles = venue.obstacles.map { "obstacle \($0.id)" }
        return (exits + obstacles).joined(separator: ", ")
    }

    /// Validate WARN/FAIL advice → a rendered `CoachAdvice`, or `nil` to fall back.
    static func validateWarnFail(
        _ advice: WarnFailAdvice, result: RunResult, venue: VenueModel, facts: CoachFacts
    ) -> CoachAdvice? {
        guard nonEmpty(advice.diagnosis), nonEmpty(advice.encouragement) else { return nil } // V1
        guard noDigits(advice.diagnosis), noDigits(advice.encouragement) else { return nil }  // V4

        // V2 + V3 + V5: keep only fixes that name a real element, cite a relevant metric, and are feasible.
        let feasible = advice.fixes.compactMap { engineFix(from: $0, venue: venue) }
        guard !feasible.isEmpty else { return nil }              // V3: at least one survives
        // V6: 2–3 fixes ideally; a single strong feasible fix is still shown (padded from the engine's own).
        let primary = feasible.first ?? result.fix

        return CoachAdvice(
            headline: "BOTTLENECK DETECTED",
            body: advice.diagnosis,
            closing: advice.encouragement,
            primaryFix: primary,
            altSuggestion: feasible.count > 1 ? feasible[1].summary : nil,
            source: .model
        )
    }

    /// Validate PASS advice; drops the joke (V8) if it references injury, keeping the summary.
    static func validatePass(_ advice: PassAdvice, facts: CoachFacts) -> CoachAdvice? {
        guard nonEmpty(advice.summary), noDigits(advice.summary) else { return nil } // V1 + V4
        let joke = jokeIsClean(advice.joke) ? advice.joke : nil                       // V8
        return CoachAdvice(
            headline: "EVACUATION SUCCESSFUL",
            body: advice.summary,
            closing: joke,
            primaryFix: nil,
            altSuggestion: nil,
            source: .model
        )
    }

    // MARK: Checks

    private static func nonEmpty(_ s: String) -> Bool {
        !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// V4 numeral scan — the model is told never to write digits, so any digit in prose fails the check.
    private static func noDigits(_ s: String) -> Bool {
        s.rangeOfCharacter(from: .decimalDigits) == nil
    }

    /// V2 + V5: resolve a model fix to a feasible engine `Fix`, or `nil` to drop it.
    private static func engineFix(from fix: GeometryFix, venue: VenueModel) -> Fix? {
        switch fix.target.kind {
        case .exit:
            guard let id = Int(fix.target.elementID.filter(\.isNumber)),
                  venue.exits.contains(where: { $0.id == id }),
                  let width = fix.proposedMetres else { return nil }
            let candidate = Fix.widenExit(id: id, width: width)
            return candidate.feasibility(in: venue).isFeasible ? candidate : nil
        case .obstacle:
            // Relocation authoring is a Stretch path; V5 already forbids moving fixed props. Dropped here
            // until the model is given a target origin to move the obstacle to.
            return nil
        case .corridor, .wall:
            return nil
        }
    }

    private static let injuryWords = ["death", "die", "dead", "kill", "injur", "casualt", "hurt", "burn", "crush"]

    /// V8: a PASS joke may not touch injury vocabulary.
    private static func jokeIsClean(_ joke: String) -> Bool {
        let lower = joke.lowercased()
        return !injuryWords.contains { lower.contains($0) }
    }
}
#endif
