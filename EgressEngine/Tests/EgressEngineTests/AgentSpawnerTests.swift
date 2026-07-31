import Testing

@testable import EgressEngine

@Suite("AgentSpawner")
struct AgentSpawnerTests {
    private func openField(_ size: GridSize, exit: GridCoord) -> (GridGeometry, FlowField) {
        (GridGeometry(size: size), FlowField(size: size, blocked: [], exits: [exit]))
    }

    @Test("same seed produces an identical spawn")
    func deterministic() {
        let (geometry, field) = openField(GridSize(width: 10, height: 10), exit: GridCoord(0, 0))
        var rngA = SeededRNG(seed: 42)
        var rngB = SeededRNG(seed: 42)
        let first = AgentSpawner.spawn(count: 25, in: geometry, field: field, rng: &rngA)
        let second = AgentSpawner.spawn(count: 25, in: geometry, field: field, rng: &rngB)
        #expect(first.map(\.position) == second.map(\.position))
        #expect(first.map(\.mobility) == second.map(\.mobility))
    }

    @Test("everyone spawns on a reachable, non-exit cell — never in a wall or a sealed pocket")
    func spawnsOnFreeFloor() {
        let geometry = GridGeometry(size: GridSize(width: 12, height: 12))
        // A column at x = 6 seals off the right half; only the left half is reachable from (0,0).
        let blocked = Set((0 ..< 12).map { GridCoord(6, $0) })
        let field = FlowField(size: geometry.size, blocked: blocked, exits: [GridCoord(0, 0)])
        var rng = SeededRNG(seed: 7)
        let agents = AgentSpawner.spawn(count: 40, in: geometry, field: field, rng: &rng)
        #expect(!agents.isEmpty)
        for agent in agents {
            let cell = geometry.cell(for: agent.position)
            #expect(field.isReachable(cell))  // reachable ⇒ not blocked and can reach an exit
            #expect(field.cost(at: cell) > 0) // not sitting on the exit itself
            #expect(cell.x < 6)               // therefore on the reachable left side
        }
    }

    @Test("count is capped by the number of free cells")
    func capsAtCapacity() {
        let (geometry, field) = openField(GridSize(width: 3, height: 3), exit: GridCoord(0, 0))
        var rng = SeededRNG(seed: 1)
        let agents = AgentSpawner.spawn(count: 100, in: geometry, field: field, rng: &rng)
        #expect(agents.count == 8) // 9 cells minus the single exit cell
    }

    @Test("agents get distinct ids and distinct starting cells")
    func distinctPlacement() {
        let (geometry, field) = openField(GridSize(width: 20, height: 20), exit: GridCoord(0, 0))
        var rng = SeededRNG(seed: 99)
        let agents = AgentSpawner.spawn(count: 50, in: geometry, field: field, rng: &rng)
        #expect(Set(agents.map(\.id)).count == 50)
        #expect(Set(agents.map(\.position)).count == 50)
    }
}