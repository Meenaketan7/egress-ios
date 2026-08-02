@testable import EgressEngine
import Foundation
import Testing

@Suite("RunEventLog")
struct RunEventLogTests {
    @Test("Records get monotonic ids and stay in emission order")
    func monotonicIDs() {
        var log = RunEventLog()
        log.record(.alarmTriggered, at: 0)
        log.record(.ignition, at: 1, location: GridCoord(2, 2))
        let last = log.record(.simEnded, at: 30, detail: "all out")
        #expect(log.events.map(\.id) == [0, 1, 2])
        #expect(last.id == 2)
        #expect(log.events.map(\.kind) == [.alarmTriggered, .ignition, .simEnded])
    }

    @Test("The summary tallies each kind and pulls casualties from the killed count")
    func summaryCounts() {
        var log = RunEventLog()
        log.record(.alarmTriggered, at: 0)
        log.record(.agentInjured, at: 10, magnitude: 1, agentID: 3)
        log.record(.agentKilled, at: 12, magnitude: 1, agentID: 3)
        log.record(.agentKilled, at: 14, magnitude: 1, agentID: 5)
        let summary = log.summary()
        #expect(summary.countsByKind[.agentKilled] == 2)
        #expect(summary.injuries == 1)
        #expect(summary.casualties == 2)
    }

    @Test("The worst jam is the densest reading, with its place and time")
    func worstJamIsDensest() {
        var log = RunEventLog()
        log.record(.densityThresholdCrossed, at: 5, location: GridCoord(1, 1), magnitude: 4.2)
        log.record(.jamFormed, at: 20, location: GridCoord(8, 3), magnitude: 6.9)
        log.record(.densityThresholdCrossed, at: 25, location: GridCoord(2, 2), magnitude: 5.1)
        let jam = log.summary().worstJam
        #expect(jam?.density == 6.9)
        #expect(jam?.location == GridCoord(8, 3))
        #expect(jam?.time == 20)
    }

    @Test("Alarm time, end reason and span come straight off the stream")
    func summaryScalars() {
        var log = RunEventLog()
        log.record(.alarmTriggered, at: 2)
        log.record(.evacuationProgress, at: 40, magnitude: 1.0)
        log.record(.simEnded, at: 47, detail: "all out")
        let summary = log.summary()
        #expect(summary.alarmTime == 2)
        #expect(summary.endReason == "all out")
        #expect(summary.duration == 45) // 47 − 2
    }

    @Test("An empty log yields an empty, jam-free summary")
    func emptySummary() {
        let summary = RunEventLog().summary()
        #expect(summary.countsByKind.isEmpty)
        #expect(summary.casualties == 0)
        #expect(summary.worstJam == nil)
        #expect(summary.alarmTime == nil)
        #expect(summary.endReason == nil)
        #expect(summary.duration == 0)
    }

    @Test("The log itself round-trips through Codable for the run transcript")
    func logIsCodable() throws {
        var log = RunEventLog()
        log.record(.ignition, at: 3, location: GridCoord(4, 4))
        log.record(.simEnded, at: 60, detail: "time cap")
        let data = try JSONEncoder().encode(log)
        let decoded = try JSONDecoder().decode(RunEventLog.self, from: data)
        #expect(decoded.events == log.events)
        // ids keep advancing after a round-trip — no collisions on further records
        var resumed = decoded
        #expect(resumed.record(.alarmTriggered, at: 61).id == 2)
    }
}
