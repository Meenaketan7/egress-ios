@testable import EgressEngine
import Testing

@Suite("SmokeField")
struct SmokeFieldTests {
    private let size = GridSize(width: 20, height: 20)
    private let source = GridCoord(10, 10)
    private let step = 1.0 / 15.0 // the 15 Hz hazard tick

    @Test("Smoke builds at a burning cell and stays within [0,1]")
    func producesAndClamps() {
        var smoke = SmokeField(size: size)
        for _ in 0 ..< 200 { smoke.tick(dt: step, sources: [source]) }
        #expect(smoke.value(at: source) > 0)
        #expect(smoke.values.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    @Test("Smoke diffuses into neighbouring cells")
    func diffuses() {
        var smoke = SmokeField(size: size)
        for _ in 0 ..< 30 { smoke.tick(dt: step, sources: [source]) }
        #expect(smoke.value(at: GridCoord(11, 10)) > 0) // reached a neighbour
    }

    @Test("Smoke fades once the fire feeding it is gone")
    func decaysWithoutSource() {
        var smoke = SmokeField(size: size)
        for _ in 0 ..< 60 { smoke.tick(dt: step, sources: [source]) }
        let litPeak = smoke.peak
        for _ in 0 ..< 600 { smoke.tick(dt: step, sources: []) } // 40 s, no fire
        #expect(smoke.peak < litPeak) // the concentration has fallen
        #expect(smoke.values.allSatisfy { $0 >= 0 && $0 <= 1 })
    }
}
