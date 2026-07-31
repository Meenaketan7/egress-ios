/// Engine-internal numerical tuning — the social-force coefficients and integration knobs of
/// build plan §2.2. The sibling of `SafetyStandards`, but the opposite kind of number: these are
/// *tuning coefficients, not citable physical constants*, so the coach never quotes them. Every
/// value is a starting point, calibrated by the faster-is-slower validation sweep and tunable here alone.
public enum SimConstants {
    // Integration
    /// H — the fixed physics substep, seconds.
    public static let substep: Double = 1.0 / 120.0
    /// DT_MAX — frame-dt clamp, so a rendering hitch slows the sim rather than exploding it.
    public static let maxFrame: Double = 1.0 / 30.0

    // Driving term
    /// τ — velocity relaxation time: how quickly an agent reaches its desired velocity, seconds.
    public static let tau: Double = 0.5
    /// V_MAX — hard speed cap above panic speed, m/s.
    public static let maxSpeed: Double = 2.5
    /// A_MAX — acceleration clamp that keeps stiff contacts stable, m/s².
    public static let maxAcceleration: Double = 20

    // Pedestrian repulsion (Helbing, §2.2)
    /// R_INT — neighbour query cutoff; the exponential is ~0 beyond this, metres.
    public static let interactionRange: Double = 1.2
    /// A_PED — repulsion strength (personal space).
    public static let pedStrength: Double = 12
    /// B_PED — repulsion falloff distance, metres.
    public static let pedFalloff: Double = 0.20
    /// K_BODY — body compression stiffness once two people overlap.
    public static let bodyStiffness: Double = 60
    /// K_FRIC — tangential friction; governs clogging and the faster-is-slower magnitude.
    public static let frictionStiffness: Double = 40

    // Wall repulsion (Helbing, §2.2)
    /// A_WALL — wall repulsion strength (how hard agents keep off walls).
    public static let wallStrength: Double = 8
    /// B_WALL — wall repulsion falloff distance, metres.
    public static let wallFalloff: Double = 0.20

    /// Desired-speed multiplier by arousal band (§2.6). Latent in S1 — nothing raises arousal yet —
    /// but wired now so panic later produces faster-is-slower without touching the force code.
    public static func arousalFactor(_ emotion: EmotionalState) -> Double {
        switch emotion {
        case .calm: 1.0
        case .uneasy: 1.1
        case .panicked: 1.5
        }
    }
}
