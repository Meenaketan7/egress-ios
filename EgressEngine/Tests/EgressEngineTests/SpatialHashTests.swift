import Testing

@testable import EgressEngine

@Suite("SpatialHash")
struct SpatialHashTests {
    @Test("candidates include every agent within the radius — no false negatives")
    func noFalseNegatives() {
        var rng = SeededRNG(seed: 5)
        let positions = (0 ..< 200).map { _ in
            Vec2(.random(in: 0 ... 12, using: &rng), .random(in: 0 ... 9, using: &rng))
        }
        // binSize == radius is the boundary case the `+1` search half-width exists to cover.
        let hash = SpatialHash(positions: positions, binSize: 1.2)
        let query = positions[0]
        let radius = 1.2
        let candidates = Set(hash.candidates(near: query, radius: radius))
        for (index, position) in positions.enumerated() where position.distance(to: query) <= radius {
            #expect(candidates.contains(index))
        }
    }

    @Test("distant agents are pruned from the candidate set")
    func prunesDistant() {
        let positions = [Vec2(0, 0), Vec2(0.3, 0.3), Vec2(50, 50)]
        let hash = SpatialHash(positions: positions, binSize: 1.0)
        let candidates = Set(hash.candidates(near: Vec2(0, 0), radius: 1.0))
        #expect(candidates.contains(0))
        #expect(candidates.contains(1))
        #expect(!candidates.contains(2))
    }

    @Test("an empty hash yields no candidates")
    func emptyHash() {
        let hash = SpatialHash(positions: [], binSize: 1.0)
        #expect(hash.candidates(near: Vec2(1, 1), radius: 2.0).isEmpty)
    }
}
