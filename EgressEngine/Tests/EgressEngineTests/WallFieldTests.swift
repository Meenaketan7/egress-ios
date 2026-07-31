import Testing

@testable import EgressEngine

@Suite("WallField")
struct WallFieldTests {
    @Test("distance grows with separation from the wall; the normal points away from it")
    func distanceAndNormal() {
        // A single wall cell at (5,5) on a 12×12 grid of 0.25 m cells.
        let size = GridSize(width: 12, height: 12)
        let field = WallField(size: size, cellSize: 0.25, blocked: [GridCoord(5, 5)])

        let near = field.distance(at: GridCoord(6, 5)) // one cell to the right
        let far = field.distance(at: GridCoord(9, 5))  // four cells to the right
        #expect(near < far)
        #expect(abs(near - 0.25) < 1e-9) // one cell, centre to centre

        let normal = field.normal(at: GridCoord(6, 5))
        #expect(normal.x > 0.99)          // points +x, away from the wall on its left
        #expect(abs(normal.y) < 1e-9)
    }

    @Test("with no walls, every cell reports no wall")
    func noWalls() {
        let field = WallField(size: GridSize(width: 8, height: 8), cellSize: 0.25, blocked: [])
        #expect(field.normal(at: GridCoord(3, 3)) == .zero)
        #expect(field.distance(at: GridCoord(3, 3)) == .greatestFiniteMagnitude)
    }
}
