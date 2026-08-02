@testable import EgressEngine
import Testing

@Suite("EscalationTracker")
struct EscalationTrackerTests {
    private func density(_ value: Double) -> EscalationTracker.Signals {
        EscalationTracker.Signals(peakDensity: value, exitBlocked: false, casualties: 0)
    }

    @Test("Congestion fires once on first crossing, then stays quiet while sustained")
    func firesOncePerCrossing() {
        var tracker = EscalationTracker()
        #expect(tracker.update(time: 1, signals: density(3.0)) == nil) // below the approach band
        #expect(tracker.update(time: 2, signals: density(4.5)) == .init(band: .congestion, time: 2))
        #expect(tracker.update(time: 3, signals: density(4.5)) == nil) // sustained — no repeat
    }

    @Test("The 6 s cooldown serialises two bands crossed close together")
    func cooldownSerialises() {
        var tracker = EscalationTracker()
        #expect(tracker.update(time: 2, signals: density(4.5)) == .init(band: .congestion, time: 2))
        // Bottleneck crosses one second later, still inside the cooldown → held.
        #expect(tracker.update(time: 3, signals: density(6.0)) == nil)
        // Once the 6 s gap has passed it lands.
        #expect(tracker.update(time: 8, signals: density(6.0)) == .init(band: .bottleneck, time: 8))
    }

    @Test("A jump straight to crush announces CRUSH only, not the rungs it leapt")
    func crushSurpassesLowerRungs() {
        var tracker = EscalationTracker()
        #expect(tracker.update(time: 1, signals: density(8.0)) == .init(band: .crush, time: 1))
        // Congestion and bottleneck were surpassed; nothing else fires while crush is sustained.
        for second in 2 ... 20 {
            #expect(tracker.update(time: Double(second), signals: density(8.0)) == nil)
        }
    }

    @Test("A band re-arms after 10 s below its threshold and can fire again")
    func rearmsAfterTenSecondsClear() {
        var tracker = EscalationTracker()
        #expect(tracker.update(time: 2, signals: density(4.5)) == .init(band: .congestion, time: 2))
        // Drop clear from t=3; the band re-arms once it has been below for 10 s (by t=13).
        for second in 3 ... 13 {
            #expect(tracker.update(time: Double(second), signals: density(1.0)) == nil)
        }
        #expect(tracker.update(time: 14, signals: density(4.5)) == .init(band: .congestion, time: 14))
    }

    @Test("The first casualty outranks a simultaneous crush, then crush follows")
    func casualtyOutranksCrush() {
        var tracker = EscalationTracker()
        let severe = EscalationTracker.Signals(peakDensity: 8.0, exitBlocked: false, casualties: 1)
        #expect(tracker.update(time: 1, signals: severe) == .init(band: .casualty, time: 1))
        for second in 2 ... 6 { _ = tracker.update(time: Double(second), signals: severe) } // ride the cooldown
        #expect(tracker.update(time: 7, signals: severe) == .init(band: .crush, time: 7))
    }

    @Test("An exit blocked by a hazard raises its own escalation")
    func exitBlockedFires() {
        var tracker = EscalationTracker()
        let blocked = EscalationTracker.Signals(peakDensity: 1.0, exitBlocked: true, casualties: 0)
        #expect(tracker.update(time: 1, signals: blocked) == .init(band: .exitBlocked, time: 1))
    }
}
