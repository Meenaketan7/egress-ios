@testable import EgressEngine
import Testing

@Suite("VerdictRules")
struct VerdictRulesTests {
    private let size = GridSize(width: 40, height: 40)
    private let cell = GridCoord(20, 20)

    /// A density field with one hot cell — a stand-in for a jammed doorway.
    private func grid(_ value: Double) -> DensityGrid {
        var values = [Double](repeating: 0, count: size.count)
        if let index = size.index(of: cell) { values[index] = value }
        return DensityGrid(size: size, values: values)
    }

    @Test("Any casualty fails the run outright (rule 1)")
    func casualtyFails() {
        var metrics = Metrics(spawnedCount: 10, clearanceTarget: 120, timeCap: 360)
        metrics.record(time: 30, dt: 1, density: DensityGrid(size: size), activeCells: []) // otherwise clean
        metrics.recordCasualty()
        let verdict = VerdictRules.default.evaluate(metrics)
        #expect(verdict.level == .fail)
        #expect(verdict.reasons.contains { $0.metricKey == .casualties })
    }

    @Test("A clean run that clears under target passes")
    func officePasses() {
        var metrics = Metrics(spawnedCount: 40, clearanceTarget: 150, timeCap: 450)
        metrics.record(time: 60, dt: 1, density: grid(2.2), activeCells: [(id: 1, cell: cell)])
        metrics.record(time: 120, dt: 1, density: DensityGrid(size: size), activeCells: []) // cleared
        let verdict = VerdictRules.default.evaluate(metrics)
        #expect(verdict.level == .pass)
        #expect(verdict.score == 98) // 100 − D(2.2)
        #expect(verdict.reasons.count == 1)
    }

    @Test("A PASS-band score can still WARN on density — the §3.2 disagreement")
    func densityWarnDespitePassBandScore() {
        var metrics = Metrics(spawnedCount: 40, clearanceTarget: 150, timeCap: 450)
        // Brief pass through a 5.4 p·m⁻² cell (1 s < 3 s dwell ⇒ not counted at-risk), then cleared.
        metrics.record(time: 1, dt: 1, density: grid(5.4), activeCells: [(id: 1, cell: cell)])
        metrics.record(time: 120, dt: 1, density: DensityGrid(size: size), activeCells: [])
        let verdict = VerdictRules.default.evaluate(metrics)
        #expect(verdict.score == 83) // PASS band (≥ 80)…
        #expect(verdict.level == .warn) // …yet the density threshold governs
        #expect(verdict.reasons.map(\.metricKey) == [.peakDensity])
    }

    @Test("Occupants still active at the cap fail the run")
    func trappedFails() {
        var metrics = Metrics(spawnedCount: 10, clearanceTarget: 120, timeCap: 360)
        let stuck = (1 ... 4).map { (id: $0, cell: cell) }
        metrics.record(time: 360, dt: 1, density: grid(3), activeCells: stuck) // never an empty frame
        let verdict = VerdictRules.default.evaluate(metrics)
        #expect(verdict.level == .fail)
        #expect(verdict.reasons.contains { $0.metricKey == .occupantsTrapped })
        #expect(metrics.trappedCount == 4)
    }

    @Test("Mass entrapment at crush density over target scores 40 and fails (§3.2)")
    func lowScoreFails() {
        var metrics = Metrics(spawnedCount: 4, clearanceTarget: 120, timeCap: 360)
        let crush = grid(8) // ≥ 7 crush band
        let crowd = (1 ... 4).map { (id: $0, cell: cell) }
        for step in 1 ... 8 { // 8 s dwell ⇒ all four count as at-risk
            metrics.record(time: Double(step), dt: 1, density: crush, activeCells: crowd)
        }
        metrics.record(time: 240, dt: 1, density: DensityGrid(size: size), activeCells: []) // clears late
        let verdict = VerdictRules.default.evaluate(metrics)
        #expect(verdict.score == 40) // 100 − D25 − R20 − T15
        #expect(verdict.level == .fail)
        #expect(verdict.reasons.contains { $0.metricKey == .safetyScore })
    }

    @Test("A WARN run collects every applicable sub-reason")
    func warnCollectsAllReasons() {
        var metrics = Metrics(spawnedCount: 4, clearanceTarget: 120, timeCap: 360)
        let dense = grid(6) // ≥ 5 caution band
        let crowd = (1 ... 4).map { (id: $0, cell: cell) }
        for step in 1 ... 8 { // dwell ⇒ at-risk fraction 1.0 ≥ 0.15
            metrics.record(time: Double(step), dt: 1, density: dense, activeCells: crowd)
        }
        metrics.record(time: 150, dt: 1, density: DensityGrid(size: size), activeCells: []) // over target
        let verdict = VerdictRules.default.evaluate(metrics)
        #expect(verdict.level == .warn)
        // 4a peak, 4b at-risk, 4c clearance, and rule 5 caution score all fire.
        #expect(Set(verdict.reasons.map(\.metricKey)) == [.peakDensity, .atRiskFraction, .clearance, .safetyScore])
    }
}
