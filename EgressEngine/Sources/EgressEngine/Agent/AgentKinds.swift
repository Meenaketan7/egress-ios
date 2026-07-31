// The three value-typed channels every agent carries. Kept free of behaviour: the
// simulation reads them, the renderer draws them, and — critically — none of them is
// ever signalled by colour alone (see the accessibility spec). Shape and pose carry
// the meaning too.

// MARK: - MobilityClass

/// Population type — sets base speed, body radius and silhouette.
/// Five types must be distinguishable *by silhouette*, not just tint.
public enum MobilityClass: String, CaseIterable, Hashable, Sendable, Codable {
    case adult
    case child
    case elderly
    case wheelchair
    case staff

    public var displayName: String {
        switch self {
        case .adult: "Adult"
        case .child: "Child"
        case .elderly: "Elderly"
        case .wheelchair: "Wheelchair user"
        case .staff: "Staff"
        }
    }
}

// MARK: - EmotionalState

/// Arousal band: calm → uneasy → panicked (§2.6). Panic raises desired speed, which is
/// what produces the faster-is-slower failure mode the product is built to show.
public enum EmotionalState: String, CaseIterable, Hashable, Sendable, Codable {
    case calm
    case uneasy
    case panicked
}

// MARK: - AgentStatus

/// Lifecycle of a single person during a run.
public enum AgentStatus: String, CaseIterable, Hashable, Sendable, Codable {
    /// On the floor, still being simulated.
    case active
    /// Reached an exit and left safely.
    case evacuated
    /// Hurt by a hazard; removed from the force calculation, retained as a soft obstacle.
    case injured
    /// Killed by a hazard.
    case dead

    public var isActive: Bool { self == .active }
    public var hasEvacuated: Bool { self == .evacuated }
    public var isCasualty: Bool { self == .injured || self == .dead }
}
