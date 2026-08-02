@testable import EgressEngine
import Testing

@Suite("HazardField")
struct HazardFieldTests {
    private let size = GridSize(width: 30, height: 30)
    private let seed = GridCoord(15, 15)
    private func allFlammable() -> [Bool] { [Bool](repeating: true, count: size.count) }

    @Test("Advancing spreads fire and raises smoke into the snapshot")
    func advanceProducesHazards() {
        var field = HazardField(size: size, flammable: allFlammable(), ignition: [seed])
        var rng = SeededRNG(seed: 3)
        field.advance(by: 10, rng: &rng) // 10 s
        let snap = field.snapshot
        #expect(!snap.fire.isEmpty) // fire present
        #expect(!snap.smoke.isEmpty) // smoke has appeared
        #expect(field.isActive)
    }

    @Test("A sub-tick advance discharges no hazard tick — the 15 Hz clock quantises")
    func subTickIsNoOp() {
        var field = HazardField(size: size, flammable: allFlammable(), ignition: [seed])
        var rng = SeededRNG(seed: 3)
        let before = field
        field.advance(by: SimConstants.hazardStep * 0.5, rng: &rng) // less than one tick
        #expect(field.fire == before.fire) // the automata did not advance…
        #expect(field.smoke == before.smoke)
    }

    @Test("Same seed reproduces an identical hazard field")
    func deterministic() {
        func run() -> HazardField {
            var field = HazardField(size: size, flammable: allFlammable(), ignition: [seed])
            var rng = SeededRNG(seed: 9)
            field.advance(by: 8, rng: &rng)
            return field
        }
        #expect(run() == run())
    }
}
