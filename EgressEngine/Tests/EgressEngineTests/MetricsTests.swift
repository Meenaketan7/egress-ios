@testable import EgressEngine
import Testing

@Suite("Metrics")
struct MetricsTests {
    private let size = GridSize(width: 40, height: 40)

    /// A density field with a single hot cell — a stand-in for one jammed doorway.
    private func grid(hot cell: GridCoord, value: Double) -> DensityGrid {
        var values = [Double](repeating: 0, count: size.count)
        if let index = size.index(of: cell) { values[index] = value }
        return DensityGrid(size: size, values: values)
    }

    @Test("A run with no frames reports cap clearance and zeroed risk")
    func defaultsBeforeAnyFrame() {
        let metrics = Metrics(spawnedCount: 10, clearanceTarget: 100, timeCap: 300)
        #expect(metrics.clearance == 300) // never cleared ⇒ the cap
        #expect(metrics.peakDensity == 0)
        #expect(metrics.atRiskAgents == 0)
        #expect(metrics.atRiskPersonSeconds == 0)
        #expect(metrics.atRiskFraction == 0)
    }

    @Test("Peak density keeps the worst cell with its location and time")
    func peakTracksWorstCell() {
        var metrics = Metrics(spawnedCount: 4, clearanceTarget: 100, timeCap: 300)
        let worst = GridCoord(20, 20)
        metrics.record(time: 1, dt: 0.5, density: grid(hot: worst, value: 6), activeCells: [(id: 1, cell: worst)])
        // A later, calmer frame must not overwrite the recorded peak.
        metrics.record(time: 2, dt: 0.5, density: grid(hot: GridCoord(10, 10), value: 4), activeCells: [])
        #expect(metrics.peakDensity == 6)
        #expect(metrics.peakLocation == worst)
        #expect(metrics.peakTime == 1)
    }

    @Test("At-risk dwell counts only agents past the 3 s threshold; person-seconds sum the rest")
    func atRiskDwellAndSum() {
        var metrics = Metrics(spawnedCount: 4, clearanceTarget: 100, timeCap: 300)
        let jam = GridCoord(20, 20)
        let hot = grid(hot: jam, value: 6) // ≥ 5 ⇒ at-risk band
        // Both agents dwell 2 s (4 frames × 0.5 s)…
        for step in 1 ... 4 {
            metrics.record(time: Double(step) * 0.5, dt: 0.5, density: hot,
                           activeCells: [(id: 1, cell: jam), (id: 2, cell: jam)])
        }
        // …then agent 1 dwells 2 s more, reaching 4 s; agent 2 stays at 2 s.
        for step in 5 ... 8 {
            metrics.record(time: Double(step) * 0.5, dt: 0.5, density: hot, activeCells: [(id: 1, cell: jam)])
        }
        #expect(metrics.atRiskPersonSeconds == 6) // 4 s + 2 s
        #expect(metrics.atRiskAgents == 1) // only agent 1 crossed 3 s
        #expect(metrics.atRiskFraction == 0.25) // 1 of 4 spawned
    }

    @Test("Density below the at-risk band banks nothing")
    func belowBandBanksNothing() {
        var metrics = Metrics(spawnedCount: 4, clearanceTarget: 100, timeCap: 300)
        let cell = GridCoord(20, 20)
        let mild = grid(hot: cell, value: 4) // < 5 ⇒ not at risk
        for step in 1 ... 20 {
            metrics.record(time: Double(step) * 0.5, dt: 0.5, density: mild, activeCells: [(id: 1, cell: cell)])
        }
        #expect(metrics.atRiskPersonSeconds == 0)
        #expect(metrics.atRiskAgents == 0)
    }

    @Test("Clearance is the first empty frame, and never moves once set")
    func clearanceLatchesOnce() {
        var metrics = Metrics(spawnedCount: 4, clearanceTarget: 100, timeCap: 300)
        let cell = GridCoord(20, 20)
        metrics.record(time: 10, dt: 0.5, density: grid(hot: cell, value: 2), activeCells: [(id: 1, cell: cell)])
        metrics.record(time: 12, dt: 0.5, density: DensityGrid(size: size), activeCells: []) // crowd gone
        metrics.record(time: 20, dt: 0.5, density: DensityGrid(size: size), activeCells: []) // stays empty
        #expect(metrics.clearance == 12)
    }

    @Test("Trapped count is the crowd still active when a run never clears")
    func trappedWhenUncleared() {
        var metrics = Metrics(spawnedCount: 5, clearanceTarget: 100, timeCap: 300)
        let cell = GridCoord(20, 20)
        // Three agents still milling at the cap — the run never sees an empty frame.
        metrics.record(time: 300, dt: 0.5, density: grid(hot: cell, value: 2),
                       activeCells: [(id: 1, cell: cell), (id: 2, cell: cell), (id: 3, cell: cell)])
        #expect(metrics.trappedCount == 3)
        #expect(metrics.clearanceTime == nil) // never latched
    }

    @Test("Casualties tally one per recorded fall")
    func casualtyTally() {
        var metrics = Metrics(spawnedCount: 5, clearanceTarget: 100, timeCap: 300)
        #expect(metrics.casualties == 0)
        metrics.recordCasualty()
        metrics.recordCasualty()
        #expect(metrics.casualties == 2)
    }

    @Test("A run that clears traps no one")
    func clearedTrapsNoOne() {
        var metrics = Metrics(spawnedCount: 5, clearanceTarget: 100, timeCap: 300)
        let cell = GridCoord(20, 20)
        metrics.record(time: 10, dt: 0.5, density: grid(hot: cell, value: 2), activeCells: [(id: 1, cell: cell)])
        metrics.record(time: 12, dt: 0.5, density: DensityGrid(size: size), activeCells: []) // everyone out
        #expect(metrics.trappedCount == 0)
        #expect(metrics.clearance == 12)
    }
}
