@testable import EgressEngine
import Testing

@Suite("DensityGrid")
struct DensityGridTests {
    /// 40×40 cells at the standard 0.25 m pitch → a 10 m × 10 m floor.
    private let geo = GridGeometry(size: GridSize(width: 40, height: 40))

    /// The divisor the builder normalises by: r = round(R_dens / cellSize) = round(0.75 / 0.25) = 3,
    /// so a 7×7 box → 49 · 0.25² = 3.0625 m². Mirrors §2.8 so the tests pin the actual spec.
    private var kernelArea: Double {
        let radiusCells = Int((SimConstants.densityRadius / geo.cellSize).rounded())
        return Double((2 * radiusCells + 1) * (2 * radiusCells + 1)) * geo.cellSize * geo.cellSize
    }

    @Test("An empty crowd yields an all-zero field")
    func emptyIsZero() {
        let grid = DensityGrid.sampled(positions: [], in: geo)
        #expect(grid.size.count == 1600)
        #expect(grid.peak == 0)
        #expect(grid.values.allSatisfy { $0 == 0 })
    }

    @Test("A single interior body peaks at exactly 1 / kernel-area")
    func singleBodyPeak() {
        // Centre of the floor — its whole 7×7 kernel is in-bounds, so no edge truncation.
        let grid = DensityGrid.sampled(positions: [Vec2(5, 5)], in: geo)
        #expect(abs(grid.peak - 1.0 / kernelArea) < 1e-9)
    }

    @Test("Interior bodies conserve mass: Σ density · cell-area == head count")
    func massConservation() {
        // Five bodies, each ≥ 3 cells from every edge, so every kernel is fully in-bounds and the
        // fixed divisor is exact — total binned mass must equal the head count regardless of overlap.
        let positions = [Vec2(2, 2), Vec2(4, 3), Vec2(5, 5), Vec2(7, 6), Vec2(8, 8)]
        let grid = DensityGrid.sampled(positions: positions, in: geo)
        let cellArea = geo.cellSize * geo.cellSize
        let totalMass = grid.values.reduce(0, +) * cellArea
        #expect(abs(totalMass - Double(positions.count)) < 1e-9)
    }

    @Test("A tight clump drives density into the at-risk band (≥ 5 p·m⁻²)")
    func clumpIsDense() {
        // 20 bodies packed into one cell — a stand-in for a doorway crush.
        let positions = Array(repeating: Vec2(5, 5), count: 20)
        let grid = DensityGrid.sampled(positions: positions, in: geo)
        #expect(grid.peak >= 5)
        #expect(abs(grid.peak - 20.0 / kernelArea) < 1e-9)
    }

    @Test("The peak cell holds the maximum density; an empty grid has none")
    func peakCellHoldsTheMax() throws {
        #expect(DensityGrid(size: geo.size).peakCell == nil)
        let grid = DensityGrid.sampled(positions: Array(repeating: Vec2(5, 5), count: 20), in: geo)
        let cell = try #require(grid.peakCell)
        #expect(grid.value(at: cell) == grid.peak) // whatever the tie-break, it is a maximum
        #expect(grid.peak >= 5) // and it is the dense clump we built
    }

    @Test("The builder is a pure function — same input, identical field")
    func deterministic() {
        let positions = [Vec2(3, 4), Vec2(6, 7), Vec2(6, 7)]
        let first = DensityGrid.sampled(positions: positions, in: geo)
        let second = DensityGrid.sampled(positions: positions, in: geo)
        #expect(first == second)
    }
}
