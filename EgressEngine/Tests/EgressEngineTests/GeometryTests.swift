import Testing
@testable import EgressEngine

@Suite("Geometry")
struct GeometryTests {

    // MARK: Vec2
    @Test("3-4-5 length and squared length are exact")
    func length() {
        #expect(Vec2(3, 4).length == 5)
        #expect(Vec2(3, 4).lengthSquared == 25)
    }

    @Test("Normalising a zero vector is safe — no NaN")
    func normalizeZero() {
        let n = Vec2.zero.normalized
        #expect(n == .zero)
        #expect(!n.x.isNaN && !n.y.isNaN)
    }

    @Test("A normalised vector has unit length")
    func normalizeUnit() {
        #expect(abs(Vec2(3, 4).normalized.length - 1) < 1e-12)
    }

    @Test("Distance and dot product")
    func distanceDot() {
        #expect(Vec2.zero.distance(to: Vec2(3, 4)) == 5)
        #expect(Vec2(1, 0).dot(Vec2(0, 1)) == 0)    // perpendicular
        #expect(Vec2(2, 3).dot(Vec2(4, 5)) == 23)   // 8 + 15
    }

    // MARK: Grid mapping — a 40×40 grid is 10 m × 10 m at 0.25 m cells
    private let geo = GridGeometry(size: GridSize(width: 40, height: 40))

    @Test("A cell centre maps back to its own cell")
    func cellRoundTrip() {
        for c in [GridCoord(0, 0), GridCoord(7, 3), GridCoord(39, 39)] {
            #expect(geo.cell(for: geo.worldCenter(of: c)) == c)
        }
    }

    @Test("Any world point sits within a cell of its centre")
    func withinHalfDiagonal() {
        let p = Vec2(1.37, 2.02)
        let centre = geo.worldCenter(of: geo.cell(for: p))
        #expect(centre.distance(to: p) <= geo.cellSize * 0.7072) // ≤ half the cell diagonal
    }

    @Test("Grid is metrically true: 40 × 0.25 m = 10 m")
    func metricExtent() {
        #expect(geo.worldWidth == 10)
        #expect(geo.worldHeight == 10)
    }

    // MARK: Flat-array indexing
    @Test("Linear index round-trips with coord, and rejects out-of-bounds")
    func indexRoundTrip() throws {
        let size = GridSize(width: 40, height: 40)
        for c in [GridCoord(0, 0), GridCoord(12, 5), GridCoord(39, 39)] {
            let i = try #require(size.index(of: c))
            #expect(size.coord(atIndex: i) == c)
        }
        #expect(size.index(of: GridCoord(-1, 0)) == nil)
        #expect(size.index(of: GridCoord(40, 0)) == nil)
        #expect(size.count == 1600)
    }

    @Test("Von Neumann neighbourhood has four cells")
    func neighbours() {
        #expect(GridCoord(5, 5).vonNeumannNeighbours.count == 4)
    }
}