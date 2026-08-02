/// The three verdict levels (§3.3) — the safety authority's call on a run.
public enum VerdictLevel: String, Sendable, Equatable {
    case pass
    case warn
    case fail
}

/// The metric a reason is about (§3.3). The AI coach emits these keys — never raw numerals — so every
/// cited number stays engine-sourced; the app maps a key to its label and unit.
public enum MetricKey: String, Sendable, Equatable {
    case casualties
    case safetyScore
    case occupantsTrapped
    case peakDensity
    case atRiskFraction
    case clearance
}

/// One line of a verdict, carrying metric + threshold + value + unit (§3.3) so a reason is never a bare
/// adjective. `text` is the ready-to-show sentence; the structured fields let the UI or coach re-render
/// it — e.g. lead with the threshold on a score/level disagreement (§3.2).
public struct VerdictReason: Equatable, Sendable {
    public let metricKey: MetricKey
    public let level: VerdictLevel
    public let actualValue: Double
    public let thresholdValue: Double
    public let unit: String
    public let text: String
}

/// The result of scoring a finished run against the rules table (§3.3). The rules table is the
/// authority; `score` rides along as communication (§3.2). `reasons` holds the level-setting reason
/// first, then any collected WARN sub-reasons.
public struct Verdict: Equatable, Sendable {
    public let level: VerdictLevel
    public let score: Int
    public let reasons: [VerdictReason]
}
