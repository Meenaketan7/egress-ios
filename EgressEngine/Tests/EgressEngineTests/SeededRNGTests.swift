@testable import EgressEngine
import Testing

@Suite("SeededRNG")
struct SeededRNGTests {
    @Test("Same seed reproduces the exact sequence")
    func determinism() {
        var a = SeededRNG(seed: 42)
        var b = SeededRNG(seed: 42)
        let seqA = (0 ..< 8).map { _ in a.next() }
        let seqB = (0 ..< 8).map { _ in b.next() }
        #expect(seqA == seqB)
    }

    @Test("Different seeds diverge")
    func differentSeeds() {
        var a = SeededRNG(seed: 1)
        var b = SeededRNG(seed: 2)
        #expect(a.next() != b.next())
    }

    @Test("Feeds the standard library's random APIs deterministically")
    func drivesStdlib() {
        var a = SeededRNG(seed: 7)
        var b = SeededRNG(seed: 7)
        let da = Double.random(in: 0 ... 1, using: &a)
        let db = Double.random(in: 0 ... 1, using: &b)
        #expect(da == db)
        #expect((0 ... 1).contains(da))
    }

    @Test("Produces a spread of values, not a stuck constant")
    func spread() {
        var rng = SeededRNG(seed: 99)
        let values = Set((0 ..< 100).map { _ in rng.next() })
        #expect(values.count == 100) // no collisions across 100 draws
    }
}
