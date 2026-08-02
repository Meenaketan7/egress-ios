import Foundation

/// One timestamped thing that happened during a run — the raw material the timeline scrubber and the
/// AI debrief are both built from (§A.5). Deliberately flat and `Codable`: `RunEventLog` is just a list
/// of these. The on-device model never sees this raw stream — only `RunEventLog.summary()` does — so a
/// `RunEvent`'s only job is to be a faithful, complete record, not a token-bounded one.
public struct RunEvent: Sendable, Codable, Equatable, Identifiable {
    public let id: Int
    public let time: TimeInterval
    public let kind: RunEventKind
    /// Grid cell the event happened at, when it has a place (jams, ignitions, casualties).
    public let location: GridCoord?
    /// Kind-specific number: cells affected, p·m⁻², fraction out, or a casualty cause code (§A.5).
    public let magnitude: Double?
    /// The agent involved, for casualty events.
    public let agentID: Int?
    /// Free text: an exit id, a recompute reason, or the sim-end reason.
    public let detail: String

    public init(
        id: Int,
        time: TimeInterval,
        kind: RunEventKind,
        location: GridCoord? = nil,
        magnitude: Double? = nil,
        agentID: Int? = nil,
        detail: String = ""
    ) {
        self.id = id
        self.time = time
        self.kind = kind
        self.location = location
        self.magnitude = magnitude
        self.agentID = agentID
        self.detail = detail
    }
}

/// The closed vocabulary of run events (§A.5). Raw `String` values keep the log human-readable in JSON
/// and give `summary()` stable keys to count by; `CaseIterable` lets the digest tally every kind.
public enum RunEventKind: String, Sendable, Codable, CaseIterable {
    case alarmTriggered          // t == alarmDelay
    case ignition                // hazard seeded; location
    case hazardSpread            // throttled ≤ 1 Hz; location, magnitude = cells affected
    case exitBlocked             // a hazard reaches an exit cell; location, exit id in detail
    case flowFieldRecomputed     // after a geometry or hazard change; reason in detail
    case densityThresholdCrossed // a cell crosses a Fruin band; location, magnitude = p·m⁻²
    case jamFormed               // at-risk density sustained ≥ N s; location, magnitude = peak density
    case agentInjured            // hazard contact; agentID, location, magnitude = cause code
    case agentKilled             // hazard contact; agentID, location, magnitude = cause code
    case evacuationProgress      // throttled ≤ 2 Hz; magnitude = fraction out
    case simEnded                // all out | time cap | casualty stop; reason in detail
}
