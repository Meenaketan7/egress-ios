@testable import EgressEngine
import Testing

@Suite("FireAutomaton")
struct FireAutomatonTests {
    /// A flammable mask that is all `false` except the given cells.
    private func mask(_ size: GridSize, flammable cells: [GridCoord]) -> [Bool] {
        var bits = [Bool](repeating: false, count: size.count)
        for cell in cells where size.index(of: cell) != nil {
            if let index = size.index(of: cell) { bits[index] = true }
        }
        return bits
    }

    @Test("A seeded cell walks igniting → burning → burnt on its timers")
    func stateMachineTimers() {
        let size = GridSize(width: 5, height: 5)
        let center = GridCoord(2, 2)
        // Only the seed is flammable ⇒ nothing spreads, no RNG is drawn — a pure timer test.
        var fire = FireAutomaton(size: size, flammable: mask(size, flammable: [center]), ignition: [center])
        var rng = SeededRNG(seed: 1)
        #expect(fire.state(at: center) == .igniting)
        fire.tick(dt: 1.0, rng: &rng) // reaches IGNITION_DELAY (1 s)
        #expect(fire.state(at: center) == .burning)
        for _ in 0 ..< 19 { fire.tick(dt: 1.0, rng: &rng) }
        #expect(fire.state(at: center) == .burning) // 19 s < BURN_DURATION
        fire.tick(dt: 1.0, rng: &rng) // 20 s
        #expect(fire.state(at: center) == .burnt)
    }

    @Test("Fire spreads to flammable neighbours and the run is reproducible")
    func spreadsDeterministically() {
        let size = GridSize(width: 40, height: 40)
        let seed = GridCoord(20, 20)
        let allFlammable = [Bool](repeating: true, count: size.count)
        func run() -> FireAutomaton {
            var fire = FireAutomaton(size: size, flammable: allFlammable, ignition: [seed])
            var rng = SeededRNG(seed: 42)
            for _ in 0 ..< 60 { fire.tick(dt: 0.5, rng: &rng) } // 30 s
            return fire
        }
        let first = run()
        let second = run()
        #expect(first == second) // same seed ⇒ identical field
        #expect(first.activeFire.count > 1) // spread beyond the seed
        #expect(first.activeFire.contains { $0 != seed }) // reached neighbours
    }

    @Test("A non-flammable cell never ignites, however long the fire rages")
    func nonFlammableStaysCold() {
        let size = GridSize(width: 10, height: 10)
        let seed = GridCoord(5, 5)
        var flammable = [Bool](repeating: true, count: size.count)
        let fireproof = GridCoord(5, 6) // right next to the seed
        if let index = size.index(of: fireproof) { flammable[index] = false }
        var fire = FireAutomaton(size: size, flammable: flammable, ignition: [seed])
        var rng = SeededRNG(seed: 7)
        for _ in 0 ..< 100 { fire.tick(dt: 0.5, rng: &rng) }
        #expect(fire.state(at: fireproof) == .unburnt)
    }
}
