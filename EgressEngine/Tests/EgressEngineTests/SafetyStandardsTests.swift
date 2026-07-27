@testable import EgressEngine
import Testing

@Suite("SafetyStandards")
struct SafetyStandardsTests {
    @Test("Grid cell is a quarter metre")
    func cellSize() {
        #expect(SafetyStandards.cellSize == 0.25)
    }

    @Test("Body radius matches the standard")
    func bodyRadius() {
        #expect(SafetyStandards.bodyRadius == 0.22)
    }
}
