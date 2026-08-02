@testable import EgressEngine
import Testing

@Suite("SafetyScore")
struct SafetyScoreTests {
    @Test("A clean run scores a perfect 100")
    func cleanRunIsPerfect() {
        let score = SafetyScore(
            casualties: 0, peakDensity: 1.5, atRiskFraction: 0, clearance: 100, clearanceTarget: 180
        )
        #expect(score.value == 100)
        #expect(score.casualtyPenalty == 0)
        #expect(score.densityPenalty == 0) // below the comfortable-band edge
        #expect(score.timePenalty == 0) // cleared under target
    }

    @Test("The plan's Concert Crush worked example scores 7 (§2.8)")
    func concertCrushExample() {
        // 3 casualties, peak 6.5 p·m⁻², 40% at risk, 210 s against a 180 s target.
        let score = SafetyScore(
            casualties: 3, peakDensity: 6.5, atRiskFraction: 0.40, clearance: 210, clearanceTarget: 180
        )
        #expect(score.casualtyPenalty == 60) // min(60, 3 × 25)
        #expect(abs(score.densityPenalty - 22.596) < 0.01) // (6.5−1.8)/5.2 × 25
        #expect(score.riskPenalty == 8.0) // 0.40 × 20
        #expect(abs(score.timePenalty - 2.5) < 1e-9) // (210−180)/180 × 15
        #expect(score.value == 7) // round(100 − 60 − 22.6 − 8 − 2.5)
    }

    @Test("A moderate run sums its penalties to a mid score")
    func moderateRun() {
        // peak 3.0 → D = (3−1.8)/5.2 × 25 = 5.769; risk 0.05 → R = 1.0; cleared under target → T = 0.
        let score = SafetyScore(
            casualties: 0, peakDensity: 3.0, atRiskFraction: 0.05, clearance: 160, clearanceTarget: 180
        )
        #expect(score.value == 93) // round(100 − 5.769 − 1.0)
    }

    @Test("Every penalty saturates at its cap")
    func penaltiesClamp() {
        let score = SafetyScore(
            casualties: 5, peakDensity: 9.0, atRiskFraction: 1.0, clearance: 999, clearanceTarget: 180
        )
        #expect(score.casualtyPenalty == 60) // capped even at 5 casualties
        #expect(score.densityPenalty == 25) // peak ≥ crush ⇒ full band
        #expect(score.riskPenalty == 20) // whole crowd at risk
        #expect(score.timePenalty == 15) // massive overrun
        #expect(score.value == 0) // clamped at the floor
    }

    @Test("Scoring a Metrics forwards the same fields as the raw initializer")
    func metricsForwarding() {
        // A run that never cleared: clearance latches to the cap (3 × target), everything else zero.
        let metrics = Metrics(spawnedCount: 4, clearanceTarget: 180, timeCap: 540)
        let viaMetrics = SafetyScore(metrics: metrics)
        let viaRaw = SafetyScore(
            casualties: 0, peakDensity: 0, atRiskFraction: 0, clearance: 540, clearanceTarget: 180
        )
        #expect(viaMetrics == viaRaw)
        #expect(viaMetrics.timePenalty == 15) // clearance = cap = 3× target ⇒ full overrun
    }
}
