import Testing

@testable import EgressEngine

@Suite("FlowField")
struct FlowFieldTests {
    // A partial wall in column x = 1 (rows 0 and 1 blocked, row 2 open), exit at the
    // top-left. The only route from the right side to the exit is down and around:
    //
    //   x █ .          legend: x = exit (cost 0), █ = blocked, . = open floor
    //   . █ .
    //   . . .
    private func obstructedField() -> FlowField {
        FlowField(
            size: GridSize(width: 3, height: 3),
            blocked: [GridCoord(1, 0), GridCoord(1, 1)],
            exits: [GridCoord(0, 0)]
        )
    }

    @Test("cost routes around a wall instead of through it")
    func routesAroundWall() {
        let field = obstructedField()
        #expect(field.cost(at: GridCoord(0, 0)) == 0) // the exit itself
        #expect(field.cost(at: GridCoord(0, 2)) == 2) // straight down the open left column
        #expect(field.cost(at: GridCoord(2, 0)) == 6) // detours down, across, and back up
    }

    @Test("blocked and off-grid cells are unreachable")
    func blockedIsUnreachable() {
        let field = obstructedField()
        #expect(field.cost(at: GridCoord(1, 0)) == .max)
        #expect(field.isReachable(GridCoord(1, 1)) == false)
        #expect(field.isReachable(GridCoord(9, 9)) == false)
    }

    @Test("direction steps downhill toward the exit")
    func directionDescends() {
        let field = obstructedField()
        let heading = field.direction(at: GridCoord(2, 1)) // cost 5; only lower neighbour is (2,2)=4
        #expect(abs(heading.x) < 1e-9)
        #expect(heading.y > 0.99) // points +y (down), toward the lower-cost cell
    }

    @Test("an exit cell has no steering direction")
    func exitHasZeroDirection() {
        let field = obstructedField()
        #expect(field.direction(at: GridCoord(0, 0)) == .zero)
    }
}