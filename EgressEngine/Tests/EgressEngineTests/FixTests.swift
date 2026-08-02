@testable import EgressEngine
import Testing

@Suite("Fix")
struct FixTests {
    /// A 5 m × 5 m hall with a narrow 0.5 m exit centred on the bottom edge, and one relocatable prop.
    private func venue() -> VenueModel {
        VenueModel(
            id: 0, name: "hall", type: .concertHall,
            geometry: GridGeometry(size: GridSize(width: 20, height: 20)),
            exits: [Exit(id: 0, a: Vec2(2.25, 5.0), b: Vec2(2.75, 5.0))],
            obstacles: [Obstacle(id: 9, origin: Vec2(1, 1), size: Vec2(1, 1), isRelocatable: true)]
        )
    }

    @Test("Widening an exit re-centres the span at the new width")
    func widenApplies() {
        let fixed = Fix.widenExit(id: 0, width: 1.2).apply(to: venue())
        let exit = fixed.exits[0]
        #expect(abs(exit.width - 1.2) < 1e-9)
        #expect(exit.center == Vec2(2.5, 5.0)) // centre unchanged
    }

    @Test("A widen below the exit minimum is rejected (V5)")
    func rejectsTooNarrow() {
        let feasibility = Fix.widenExit(id: 0, width: 0.8).feasibility(in: venue())
        #expect(!feasibility.isFeasible)
    }

    @Test("A widen that would leave the venue bounds is rejected (V5)")
    func rejectsOutOfBounds() {
        // 6 m span centred at x = 2.5 would run from −0.5 m to 5.5 m — off both ends of a 5 m room.
        let feasibility = Fix.widenExit(id: 0, width: 6.0).feasibility(in: venue())
        #expect(!feasibility.isFeasible)
    }

    @Test("A reasonable widen is feasible")
    func acceptsReasonableWiden() {
        #expect(Fix.widenExit(id: 0, width: 1.5).feasibility(in: venue()).isFeasible)
    }

    @Test("Relocating a fixed obstacle is rejected (V5)")
    func rejectsFixedObstacle() {
        let structural = VenueModel(
            id: 1, name: "x", type: .office,
            geometry: GridGeometry(size: GridSize(width: 20, height: 20)),
            exits: [Exit(id: 0, a: Vec2(2, 5), b: Vec2(3, 5))],
            obstacles: [Obstacle(id: 5, origin: Vec2(1, 1), size: Vec2(1, 1), isRelocatable: false)]
        )
        let feasibility = Fix.relocateObstacle(id: 5, origin: Vec2(3, 3)).feasibility(in: structural)
        #expect(!feasibility.isFeasible)
    }

    @Test("Adding an exit appends one with a fresh id")
    func addExitApplies() {
        let fixed = Fix.addExit(a: Vec2(4, 0), b: Vec2(5, 0)).apply(to: venue())
        #expect(fixed.exits.count == 2)
        #expect(fixed.exits.last?.id == 1) // max(0) + 1
    }
}
