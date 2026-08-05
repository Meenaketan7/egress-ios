@testable import EgressEngine
import Testing

@Suite("RoomEnclosure")
struct RoomEnclosureTests {
    /// 3 m × 3 m room on the default 0.25 m grid → 12 × 12 cells.
    private func grid() -> GridGeometry {
        GridGeometry(size: GridSize(width: 12, height: 12))
    }

    /// Four walls forming a closed 1 m box from (1,1) to (2,2) → cells 4…8 on each edge.
    private func closedBox() -> [Wall] {
        [
            Wall(a: Vec2(1, 1), b: Vec2(2, 1)), // top
            Wall(a: Vec2(1, 2), b: Vec2(2, 2)), // bottom
            Wall(a: Vec2(1, 1), b: Vec2(1, 2)), // left
            Wall(a: Vec2(2, 1), b: Vec2(2, 2)) // right
        ]
    }

    @Test("a closed wall loop marks everything outside it as exterior, and nothing inside")
    func closedLoopEncloses() {
        let exterior = RoomEnclosure.exterior(walls: closedBox(), exits: [], geometry: grid())
        #expect(!exterior.isEmpty)
        #expect(exterior.contains(GridCoord(0, 0))) // a corner, clearly outside the box
        #expect(!exterior.contains(GridCoord(6, 6))) // the centre of the box — inside, stays floor
    }

    @Test("no walls means no enclosure — the whole grid stays floor")
    func noWallsNoEnclosure() {
        #expect(RoomEnclosure.exterior(walls: [], exits: [], geometry: grid()).isEmpty)
    }

    @Test("an open wall run (not a loop) encloses nothing")
    func openRunEnclosesNothing() {
        let wall = [Wall(a: Vec2(1, 1), b: Vec2(2, 1))] // a single segment — no interior
        #expect(RoomEnclosure.exterior(walls: wall, exits: [], geometry: grid()).isEmpty)
    }

    @Test("a plain gap in the loop lets the flood leak in — no enclosure")
    func gapLeaks() {
        // The closed box, but with the bottom edge left open in the middle (a doorway with no door).
        let gappy = [
            Wall(a: Vec2(1, 1), b: Vec2(2, 1)), // top
            Wall(a: Vec2(1, 1), b: Vec2(1, 2)), // left
            Wall(a: Vec2(2, 1), b: Vec2(2, 2)), // right
            Wall(a: Vec2(1, 2), b: Vec2(1.25, 2)), // bottom-left stub
            Wall(a: Vec2(1.75, 2), b: Vec2(2, 2)) // bottom-right stub — gap between the stubs
        ]
        #expect(RoomEnclosure.exterior(walls: gappy, exits: [], geometry: grid()).isEmpty)
    }

    @Test("an exit across the gap seals the doorway, so the loop encloses again")
    func exitSealsDoorway() {
        let gappy = [
            Wall(a: Vec2(1, 1), b: Vec2(2, 1)),
            Wall(a: Vec2(1, 1), b: Vec2(1, 2)),
            Wall(a: Vec2(2, 1), b: Vec2(2, 2)),
            Wall(a: Vec2(1, 2), b: Vec2(1.25, 2)),
            Wall(a: Vec2(1.75, 2), b: Vec2(2, 2))
        ]
        let exit = [Exit(id: 0, a: Vec2(1.25, 2), b: Vec2(1.75, 2))]
        let exterior = RoomEnclosure.exterior(walls: gappy, exits: exit, geometry: grid())
        #expect(!exterior.isEmpty)
        #expect(!exterior.contains(GridCoord(6, 6))) // the box interior is still floor
        #expect(exterior.contains(GridCoord(0, 0))) // the outside is blocked
    }
}
