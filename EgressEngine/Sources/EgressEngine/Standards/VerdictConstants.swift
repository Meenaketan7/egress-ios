/// Verdict thresholds (§3.1) — the safety authority's dials, in one tunable place and surfaced in the
/// results UI. Distinct from `SafetyStandards` (physical, citable) and `SimConstants` (physics knobs):
/// these decide PASS / WARN / FAIL. The density band edges live in `SafetyStandards`
/// (`densityAtRisk` = caution, `densityCrush` = crush); the verdict reads those, so the numbers the
/// coach cites have a single source of truth.
public enum VerdictConstants {
    /// At or above this Safety Score ⇒ PASS-eligible.
    public static let passScoreMin = 80
    /// Below this Safety Score ⇒ FAIL, regardless of casualties.
    public static let failScoreMax = 50
    /// Fraction of occupants held above the at-risk band beyond the dwell time that trips a WARN.
    public static let atRiskFractionWarn = 0.15
    /// Any occupant unevacuated at the cap ⇒ FAIL — in a safety product, one trapped person is a failure.
    public static let trappedFailCount = 1

    /// Live-escalation anti-spam (§3.3): the minimum gap, in seconds, between any two in-sim escalations.
    public static let escalationCooldown = 6.0
    /// Seconds a band must stay below its threshold before it can fire again (§3.3).
    public static let escalationRearm = 10.0
    /// The "approaching" density (p·m⁻²) that arms the first, amber congestion escalation — below the
    /// at-risk band, so the banner warns before the crowd reaches `SafetyStandards.densityAtRisk`.
    public static let escalationApproachDensity = 4.0
}
