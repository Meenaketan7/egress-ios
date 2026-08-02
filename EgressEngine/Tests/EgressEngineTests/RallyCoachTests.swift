@testable import EgressEngine
import Testing

@Suite("RallyCoach")
struct RallyCoachTests {
    /// A metrics fold that jams `agents` into `cell` at crush density for 8 s, then clears at `clearedAt`.
    private func jammedMetrics(
        geometry: GridGeometry, cell: GridCoord, agents: Int, target: Double, clearedAt: Double
    ) -> Metrics {
        var metrics = Metrics(spawnedCount: agents, clearanceTarget: target, timeCap: 540)
        var values = [Double](repeating: 0, count: geometry.size.count)
        if let index = geometry.size.index(of: cell) { values[index] = 8 } // crush band
        let density = DensityGrid(size: geometry.size, values: values)
        let crowd = (1 ... agents).map { (id: $0, cell: cell) }
        for step in 1 ... 8 {
            metrics.record(time: Double(step), dt: 1, density: density, activeCells: crowd)
        }
        metrics.record(time: clearedAt, dt: 1, density: DensityGrid(size: geometry.size), activeCells: [])
        return metrics
    }

    @Test("A jammed run gets a widen-exit fix, wider than the current door and feasible")
    func suggestsWiderExit() {
        let geometry = GridGeometry(size: GridSize(width: 20, height: 20))
        let venue = VenueModel(
            id: 0, name: "hall", type: .concertHall, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.25, 5.0), b: Vec2(2.75, 5.0))] // 0.5 m door
        )
        let jam = geometry.cell(for: Vec2(2.5, 4.75))
        let metrics = jammedMetrics(geometry: geometry, cell: jam, agents: 20, target: 180, clearedAt: 200)
        let verdict = VerdictRules.default.evaluate(metrics)
        #expect(verdict.level != .pass)
        guard let fix = RallyCoach.default.suggest(for: verdict, metrics: metrics, in: venue) else {
            Issue.record("expected a fix for a jammed run")
            return
        }
        guard case let .widenExit(id, width) = fix else {
            Issue.record("expected a widen-exit fix, got \(fix)")
            return
        }
        #expect(id == 0)
        #expect(width > 0.5) // wider than the current door
        #expect(fix.feasibility(in: venue).isFeasible)
    }

    @Test("A passing run gets no fix")
    func noFixForPass() {
        let geometry = GridGeometry(size: GridSize(width: 20, height: 20))
        let venue = VenueModel(
            id: 0, name: "hall", type: .office, geometry: geometry,
            exits: [Exit(id: 0, a: Vec2(2.0, 5.0), b: Vec2(3.2, 5.0))]
        )
        var metrics = Metrics(spawnedCount: 10, clearanceTarget: 150, timeCap: 450)
        metrics.record(time: 60, dt: 1, density: DensityGrid(size: geometry.size), activeCells: []) // clean
        let verdict = VerdictRules.default.evaluate(metrics)
        #expect(verdict.level == .pass)
        #expect(RallyCoach.default.suggest(for: verdict, metrics: metrics, in: venue) == nil)
    }

    @Test("The fix targets the exit nearest the jam, not a far one")
    func targetsNearestExit() {
        let geometry = GridGeometry(size: GridSize(width: 40, height: 40)) // 10 m
        let venue = VenueModel(
            id: 0, name: "hall", type: .concertHall, geometry: geometry,
            exits: [
                Exit(id: 0, a: Vec2(0.5, 0.0), b: Vec2(1.0, 0.0)), // top-left
                Exit(id: 1, a: Vec2(9.0, 10.0), b: Vec2(9.5, 10.0)), // bottom-right
            ]
        )
        let jam = geometry.cell(for: Vec2(9.2, 9.5)) // hard by exit 1
        let metrics = jammedMetrics(geometry: geometry, cell: jam, agents: 20, target: 180, clearedAt: 300)
        let verdict = VerdictRules.default.evaluate(metrics)
        guard let fix = RallyCoach.default.suggest(for: verdict, metrics: metrics, in: venue),
              case let .widenExit(id, _) = fix else {
            Issue.record("expected a widen-exit fix")
            return
        }
        #expect(id == 1) // the jammed exit, not the far one
    }
}
