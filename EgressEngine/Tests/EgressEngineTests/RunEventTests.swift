@testable import EgressEngine
import Foundation
import Testing

@Suite("RunEvent")
struct RunEventTests {
    @Test("The convenience init leaves the optional payload nil and the detail empty")
    func defaultsAreEmpty() {
        let event = RunEvent(id: 1, time: 12.5, kind: .alarmTriggered)
        #expect(event.location == nil)
        #expect(event.magnitude == nil)
        #expect(event.agentID == nil)
        #expect(event.detail.isEmpty)
    }

    @Test("A fully-populated event round-trips through Codable unchanged")
    func codableRoundTrip() throws {
        let event = RunEvent(
            id: 7, time: 42.0, kind: .agentKilled,
            location: GridCoord(3, 4), magnitude: 2, agentID: 88, detail: "fire"
        )
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(RunEvent.self, from: data)
        #expect(decoded == event)
    }

    @Test("Kinds encode to their stable raw strings")
    func rawValuesAreStable() {
        #expect(RunEventKind.densityThresholdCrossed.rawValue == "densityThresholdCrossed")
        #expect(RunEventKind(rawValue: "simEnded") == .simEnded)
        #expect(RunEventKind.allCases.count == 11)
    }

    @Test("GridCoord itself now round-trips through Codable")
    func gridCoordIsCodable() throws {
        let coord = GridCoord(5, -2)
        let data = try JSONEncoder().encode(coord)
        #expect(try JSONDecoder().decode(GridCoord.self, from: data) == coord)
    }
}
