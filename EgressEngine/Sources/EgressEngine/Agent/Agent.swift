/// A single person as the *simulation* sees them — the full physical state the integrator and
/// social force act on. Deliberately richer than `AgentRender` (the slim per-frame value that
/// crosses to the UI): this carries velocity plus the fixed traits — body radius and
/// free-walking speed — that the mock never needed.
public struct Agent: Identifiable, Sendable {
    public let id: Int
    /// Position in metres (world space).
    public var position: Vec2
    /// Velocity in m/s. Zero at spawn; the integrator evolves it.
    public var velocity: Vec2
    public let mobility: MobilityClass
    public var emotion: EmotionalState
    public var status: AgentStatus

    /// Body radius in metres — fixed per person.
    public let radius: Double
    /// Free-walking desired speed in m/s, before any panic scaling — fixed per person.
    public let baseSpeed: Double

    public init(id: Int, position: Vec2, mobility: MobilityClass) {
        self.id = id
        self.position = position
        velocity = .zero
        self.mobility = mobility
        emotion = .calm
        status = .active
        radius = SafetyStandards.bodyRadius
        baseSpeed = Self.freeSpeed(for: mobility)
    }

    /// The slim value the renderer consumes — position plus the three display channels, nothing
    /// physical. Makes building a `SimulationSnapshot` a one-liner: `agents.map(\.render)`.
    public var render: AgentRender {
        AgentRender(id: id, position: position, emotion: emotion, mobility: mobility, status: status)
    }

    /// Free-walking speed by population type (m/s). These live here for now; they move into
    /// `SimConstants` alongside the social-force parameters when we build the crowd force (step 4).
    private static func freeSpeed(for mobility: MobilityClass) -> Double {
        switch mobility {
        case .adult, .staff: 1.3
        case .child: 0.9
        case .elderly: 0.7
        case .wheelchair: 0.8
        }
    }
}
