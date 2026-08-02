import Foundation

/// The ordered record of everything that happened in one run (§A.5) — owned by `Simulation` as a
/// value, exactly like `Metrics`. It is the persisted artifact behind the exportable run transcript
/// (§3.6); the on-device AI never sees it directly, only the reduced `summary()`.
public struct RunEventLog: Sendable, Codable {
    public private(set) var events: [RunEvent] = []
    private var nextID = 0

    public init() {}

    /// Append an event, stamping it with the next monotonic id, and hand the stored event back.
    /// Callers describe what happened and when; the log owns the id invariant.
    @discardableResult
    public mutating func record(
        _ kind: RunEventKind,
        at time: TimeInterval,
        location: GridCoord? = nil,
        magnitude: Double? = nil,
        agentID: Int? = nil,
        detail: String = ""
    ) -> RunEvent {
        let event = RunEvent(
            id: nextID, time: time, kind: kind,
            location: location, magnitude: magnitude, agentID: agentID, detail: detail
        )
        nextID += 1
        events.append(event)
        return event
    }

    /// The token-bounded structured digest (§A.5) — the *only* run data the on-device model is shown.
    /// A faithful reduction of the engine-sourced stream, never the raw per-frame data.
    public func summary() -> RunSummary { RunSummary(events: events) }
}

/// A compact, engine-grounded reduction of a run's events for the AI debrief (§A.5). Derived on demand,
/// never persisted — so it carries no `Codable`; the `RunEventLog` is the artifact that gets stored.
public struct RunSummary: Sendable, Equatable {
    /// How many of each kind fired — the digest's headline, and what keeps its token cost bounded.
    public let countsByKind: [RunEventKind: Int]
    public let injuries: Int
    public let casualties: Int
    /// The single worst congestion reading seen: where, how dense (p·m⁻²), and when.
    public let worstJam: JamSummary?
    /// When the alarm sounded, if it did.
    public let alarmTime: TimeInterval?
    /// Why the run ended — the `simEnded` detail — if it ended.
    public let endReason: String?
    /// Span of the log, first event to last.
    public let duration: TimeInterval

    public struct JamSummary: Sendable, Equatable {
        public let location: GridCoord?
        public let density: Double
        public let time: TimeInterval
    }

    init(events: [RunEvent]) {
        countsByKind = Dictionary(grouping: events, by: \.kind).mapValues(\.count)
        injuries = countsByKind[.agentInjured] ?? 0
        casualties = countsByKind[.agentKilled] ?? 0
        let jams = events.filter {
            ($0.kind == .densityThresholdCrossed || $0.kind == .jamFormed) && $0.magnitude != nil
        }
        if let worst = jams.max(by: { ($0.magnitude ?? 0) < ($1.magnitude ?? 0) }) {
            worstJam = JamSummary(location: worst.location, density: worst.magnitude ?? 0, time: worst.time)
        } else {
            worstJam = nil
        }
        alarmTime = events.first { $0.kind == .alarmTriggered }?.time
        endReason = events.last { $0.kind == .simEnded }?.detail
        let times = events.map(\.time)
        duration = (times.max() ?? 0) - (times.min() ?? 0)
    }
}
