@testable import EgressEngine
import Testing

@Suite("EmoteTracker")
struct EmoteTrackerTests {
    /// A calm, unremarkable adult at the origin — the baseline each test perturbs one field of.
    private func base(
        id: Int = 1,
        position: Vec2 = .zero,
        mobility: MobilityClass = .adult,
        emotion: EmotionalState = .calm,
        status: AgentStatus = .active,
        speed: Double = 1.0,
        density: Double = 0,
        nearFire: Bool = false,
        nearExit: Bool = false
    ) -> EmoteInput {
        EmoteInput(
            id: id, position: position, mobility: mobility, emotion: emotion,
            status: status, speed: speed, localDensity: density, nearFire: nearFire, nearExit: nearExit
        )
    }

    @Test("A calm crowd emits nothing")
    func calmEmitsNothing() {
        var tracker = EmoteTracker()
        #expect(tracker.update(agents: [base()], time: 1).isEmpty)
    }

    @Test("Astonished fires the frame an agent first turns panicked")
    func astonishedOnFirstPanic() {
        var tracker = EmoteTracker()
        _ = tracker.update(agents: [base(emotion: .calm)], time: 1)
        // First panic away from the fire is a shock (astonished); panic *at* the fire is distress instead.
        let out = tracker.update(agents: [base(emotion: .panicked)], time: 2)
        #expect(out[1] == .astonished)
    }

    @Test("Frustrated fires when an agent stalls inside a crowd")
    func frustratedOnStallInCrowd() {
        var tracker = EmoteTracker()
        let out = tracker.update(agents: [base(emotion: .uneasy, speed: 0.05, density: 4.5)], time: 1)
        #expect(out[1] == .frustrated)
    }

    @Test("Confused fires when an uneasy agent hesitates in open space")
    func confusedOnHesitation() {
        var tracker = EmoteTracker()
        let out = tracker.update(agents: [base(emotion: .uneasy, speed: 0.05, density: 0.5)], time: 1)
        #expect(out[1] == .confused)
    }

    @Test("Distressed fires for a living agent trapped against the fire")
    func distressedWhenTrappedByFire() {
        var tracker = EmoteTracker()
        let out = tracker.update(
            agents: [base(emotion: .panicked, speed: 0.05, density: 5, nearFire: true)], time: 1
        )
        #expect(out[1] == .distressed)
    }

    @Test("Resolute fires for staff standing by a panicked neighbour")
    func resoluteForStaffCalmingNeighbour() {
        var tracker = EmoteTracker()
        let staff = base(id: 1, position: Vec2(0, 0), mobility: .staff, emotion: .calm)
        let panicked = base(id: 2, position: Vec2(1, 0), emotion: .panicked)
        let out = tracker.update(agents: [staff, panicked], time: 1)
        #expect(out[1] == .resolute)
    }

    @Test("Relieved fires as an agent reaches the exit")
    func relievedNearExit() {
        var tracker = EmoteTracker()
        let out = tracker.update(agents: [base(nearExit: true)], time: 1)
        #expect(out[1] == .relieved)
    }

    @Test("An emote clears once its lifetime elapses with no fresh trigger")
    func emoteExpires() {
        var tracker = EmoteTracker()
        _ = tracker.update(agents: [base(emotion: .calm)], time: 0)
        #expect(tracker.update(agents: [base(emotion: .panicked)], time: 1)[1] == .astonished)
        // Calm again and well past the lifetime — the glyph should be gone.
        let out = tracker.update(agents: [base(emotion: .panicked)], time: 5)
        #expect(out[1] == nil)
    }
}
