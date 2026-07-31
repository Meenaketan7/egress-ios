import Testing

@testable import EgressEngine

@Suite("BlockedCells")
struct BlockedCellsTests {
    // A 2 m × 2 m room on the default 0.25 m grid → 8 × 8 cells.
    private func grid() -> GridGeometry { GridGeometry(size: GridSize(width: 8, height: 8)) }

    private func venue(walls: [Wall] = [], obstacles: [Obstacle] = []) -> VenueModel {
        VenueModel(
            id: 0, name: "test", type: .concertHall, geometry: grid(),
            walls: walls, exits: [Exit(id: 0, a: Vec2(0, 2), b: Vec2(0.5, 2))], obstacles: obstacles
        )
    }

    @Test("an obstacle blocks exactly the cells its box overlaps")
    func obstacleFootprint() {
        let box = Obstacle(id: 0, origin: Vec2(0.5, 0.5), size: Vec2(0.5, 0.5), isRelocatable: true)
        let blocked = BlockedCells.of(venue(obstacles: [box]))
        #expect(blocked == [GridCoord(2, 2), GridCoord(3, 2), GridCoord(2, 3), GridCoord(3, 3)])
    }

    @Test("relocatable and structural obstacles both block — isRelocatable is not about passability")
    func relocatableStillBlocks() {
        let movable = Obstacle(id: 0, origin: Vec2(0.5, 0.5), size: Vec2(0.25, 0.25), isRelocatable: true)
        let fixed = Obstacle(id: 1, origin: Vec2(1.0, 1.0), size: Vec2(0.25, 0.25), isRelocatable: false)
        let blocked = BlockedCells.of(venue(obstacles: [movable, fixed]))
        #expect(blocked.contains(GridCoord(2, 2)))
        #expect(blocked.contains(GridCoord(4, 4)))
    }

    @Test("a wall rasterises to a connected column that seals the grid")
    func wallSeals() {
        let wall = Wall(a: Vec2(1.0, 0.0), b: Vec2(1.0, 2.0)) // vertical at x = 1 m → cell column 4
        let blocked = BlockedCells.of(venue(walls: [wall]))
        for y in 0 ..< 8 { #expect(blocked.contains(GridCoord(4, y))) }

        // A flood from the left edge cannot cross the full-height wall.
        let field = FlowField(size: grid().size, blocked: blocked, exits: [GridCoord(0, 0)])
        #expect(field.isReachable(GridCoord(3, 3)))          // near side, reachable
        #expect(field.isReachable(GridCoord(5, 3)) == false) // far side, sealed off
    }

    @Test("cells are clamped to the grid — an out-of-bounds box adds nothing invalid")
    func clampsToGrid() {
        let overhang = Obstacle(id: 0, origin: Vec2(1.75, 1.75), size: Vec2(1.0, 1.0), isRelocatable: false)
        let blocked = BlockedCells.of(venue(obstacles: [overhang]))
        #expect(blocked.allSatisfy { grid().size.contains($0) })
        #expect(blocked.contains(GridCoord(7, 7))) // only the in-bounds corner survives
    }
}