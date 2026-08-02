import Foundation

/// The 0–100 Safety Score (§2.8) — a run's four failure pressures rolled into one number the demo
/// shows and the coach explains. Communication, not authority: PASS/FAIL is the rules table's call;
/// this score says *how* bad and *why*. Each penalty is kept beside the total so the reasons can name
/// the term that dominated (e.g. "density cost you 23 points").
///
/// Score = round(clamp(100 − C − D − R − T, 0, 100)), where:
///   C  casualties · min(60, casualties × 25)                     — one death already dominates
///   D  density    · clamp((peak − 1.8)/(7 − 1.8), 0, 1) × 25     — comfortable-band edge → crush
///   R  risk       · atRiskFraction × 20                          — share that lingered at ≥ 5 p·m⁻²
///   T  time       · clamp((clearance − target)/target, 0, 1) × 15 — overrun past the egress goal
public struct SafetyScore: Equatable, Sendable {
    /// The reported score, 0...100.
    public let value: Int
    /// Casualty penalty C.
    public let casualtyPenalty: Double
    /// Density penalty D.
    public let densityPenalty: Double
    /// At-risk penalty R.
    public let riskPenalty: Double
    /// Time-overrun penalty T.
    public let timePenalty: Double

    /// Score straight from the five inputs — the pure formula, independent of where the numbers came
    /// from, so it unit-tests against the plan's worked examples with no `Simulation`.
    public init(
        casualties: Int,
        peakDensity: Double,
        atRiskFraction: Double,
        clearance: TimeInterval,
        clearanceTarget: TimeInterval
    ) {
        casualtyPenalty = min(60, Double(casualties) * 25)

        let band = SafetyStandards.densityCrush - SafetyStandards.densityComfortable
        densityPenalty = Self.clamp01((peakDensity - SafetyStandards.densityComfortable) / band) * 25

        riskPenalty = atRiskFraction * 20

        let overrun = clearanceTarget > 0 ? (clearance - clearanceTarget) / clearanceTarget : 0
        timePenalty = Self.clamp01(overrun) * 15

        let raw = 100 - casualtyPenalty - densityPenalty - riskPenalty - timePenalty
        value = Int(min(100, max(0, raw)).rounded())
    }

    /// Score a completed run's metrics — forwards exactly the fields the formula reads.
    public init(metrics: Metrics) {
        self.init(
            casualties: metrics.casualties,
            peakDensity: metrics.peakDensity,
            atRiskFraction: metrics.atRiskFraction,
            clearance: metrics.clearance,
            clearanceTarget: metrics.clearanceTarget
        )
    }

    private static func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }
}
