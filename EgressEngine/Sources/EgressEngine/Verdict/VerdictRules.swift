import Foundation

/// Evaluates a finished run against the verdict rules table (§3.3). The order is fixed and the **first
/// matching rule decides the level**; all applicable WARN sub-reasons are then collected so the results
/// card can list them. The rules table is the safety authority — the Safety Score is only
/// communication, and the two may legitimately disagree in a narrow band (§3.2), which is why the level
/// is never read off the score.
///
/// S2 scope: rules 1–3 (FAIL), 4a/4b/4c and 5 (WARN), 6 (PASS). Deferred with the systems they need —
/// rule 4d (aisle width) awaits the clear-width analysis; the escalation timeline awaits `RunEventLog`;
/// the plan's `venue`/`log` parameters arrive with those.
public struct VerdictRules: Sendable {
    public static let `default` = VerdictRules()

    public init() {}

    public func evaluate(_ metrics: Metrics) -> Verdict {
        let score = SafetyScore(metrics: metrics)

        // FAIL rules (1–3). The first to match sets the level; collect every one that applies.
        var failures: [VerdictReason] = []
        if metrics.casualties > 0 {
            failures.append(.casualties(metrics.casualties))
        }
        if score.value < VerdictConstants.failScoreMax {
            failures.append(.lowScore(score.value))
        }
        if metrics.trappedCount >= VerdictConstants.trappedFailCount {
            failures.append(.trapped(metrics.trappedCount, cap: metrics.timeCap))
        }
        if !failures.isEmpty {
            return Verdict(level: .fail, score: score.value, reasons: failures)
        }

        // WARN rules (4a–4c, 5). Collect every sub-reason so the card can list them.
        var warnings: [VerdictReason] = []
        if metrics.peakDensity >= SafetyStandards.densityAtRisk {
            warnings.append(.peakDensity(metrics.peakDensity))
        }
        if metrics.atRiskFraction >= VerdictConstants.atRiskFractionWarn {
            warnings.append(.atRisk(metrics.atRiskFraction))
        }
        if metrics.clearance > metrics.clearanceTarget {
            warnings.append(.slowClearance(metrics.clearance, target: metrics.clearanceTarget))
        }
        if score.value >= VerdictConstants.failScoreMax, score.value < VerdictConstants.passScoreMin {
            warnings.append(.cautionScore(score.value))
        }
        if !warnings.isEmpty {
            return Verdict(level: .warn, score: score.value, reasons: warnings)
        }

        // Rule 6: nothing tripped ⇒ PASS.
        return Verdict(level: .pass, score: score.value, reasons: [.pass(metrics)])
    }
}

// MARK: - Reason rendering (§3.3 templates)

private extension VerdictReason {
    static func casualties(_ count: Int) -> VerdictReason {
        let text = "\(count) casualt\(count == 1 ? "y" : "ies") during the evacuation"
        return VerdictReason(
            metricKey: .casualties, level: .fail, actualValue: Double(count),
            thresholdValue: 0, unit: "people", text: text
        )
    }

    static func lowScore(_ score: Int) -> VerdictReason {
        VerdictReason(
            metricKey: .safetyScore, level: .fail, actualValue: Double(score),
            thresholdValue: Double(VerdictConstants.failScoreMax), unit: "points",
            text: "Safety Score \(score) below the floor of \(VerdictConstants.failScoreMax)"
        )
    }

    static func trapped(_ count: Int, cap: TimeInterval) -> VerdictReason {
        let plural = count == 1 ? "" : "s"
        let text = "\(count) occupant\(plural) unable to reach an exit within \(seconds(cap))"
        return VerdictReason(
            metricKey: .occupantsTrapped, level: .fail, actualValue: Double(count),
            thresholdValue: Double(VerdictConstants.trappedFailCount), unit: "people", text: text
        )
    }

    static func peakDensity(_ peak: Double) -> VerdictReason {
        let caution = density(SafetyStandards.densityAtRisk)
        return VerdictReason(
            metricKey: .peakDensity, level: .warn, actualValue: peak,
            thresholdValue: SafetyStandards.densityAtRisk, unit: "p·m⁻²",
            text: "Peak density \(density(peak)) p·m⁻² (caution ≥ \(caution) p·m⁻²)"
        )
    }

    static func atRisk(_ fraction: Double) -> VerdictReason {
        let band = density(SafetyStandards.densityAtRisk)
        let dwell = seconds(SimConstants.atRiskDwell)
        let text = "\(percent(fraction)) of occupants held above \(band) p·m⁻² for over \(dwell)"
        return VerdictReason(
            metricKey: .atRiskFraction, level: .warn, actualValue: fraction,
            thresholdValue: VerdictConstants.atRiskFractionWarn, unit: "%", text: text
        )
    }

    static func slowClearance(_ clearance: TimeInterval, target: TimeInterval) -> VerdictReason {
        VerdictReason(
            metricKey: .clearance, level: .warn, actualValue: clearance, thresholdValue: target,
            unit: "s", text: "Clearance \(seconds(clearance)) exceeds the \(seconds(target)) target"
        )
    }

    static func cautionScore(_ score: Int) -> VerdictReason {
        VerdictReason(
            metricKey: .safetyScore, level: .warn, actualValue: Double(score),
            thresholdValue: Double(VerdictConstants.passScoreMin), unit: "points",
            text: "Safety Score \(score) in the caution band"
        )
    }

    static func pass(_ metrics: Metrics) -> VerdictReason {
        let text = "Cleared in \(seconds(metrics.clearance)) · peak \(density(metrics.peakDensity)) p·m⁻² · zero casualties"
        return VerdictReason(
            metricKey: .clearance, level: .pass, actualValue: metrics.clearance,
            thresholdValue: metrics.clearanceTarget, unit: "s", text: text
        )
    }

    // Rendering helpers — whole seconds, density to one decimal, fraction as a percentage.
    private static func seconds(_ value: TimeInterval) -> String { "\(Int(value.rounded())) s" }
    private static func density(_ value: Double) -> String { String(format: "%.1f", value) }
    private static func percent(_ fraction: Double) -> String { "\(Int((fraction * 100).rounded()))%" }
}
