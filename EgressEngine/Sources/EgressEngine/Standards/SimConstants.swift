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
    // Density field (§2.8)
    /// R_dens — density smoothing radius: the box-blur kernel reaches this far, metres. A readout
    /// smoothing knob (not a force, not a citable standard), so it lives here, not in SafetyStandards.
    public static let densityRadius: Double = 0.75
        /// AT_RISK_DWELL — seconds an agent must dwell in the at-risk band before it counts as at-risk (§2.8).
    public static let atRiskDwell: Double = 3.0

    /// Desired-speed multiplier for a merely uneasy agent (§2.6) — fixed.
    public static let uneasyArousal: Double = 1.1
    /// Default desired-speed multiplier for a panicked agent (§2.6). The one arousal band the
    /// validation sweep drives — `SimulationConfig.panicSpeed` overrides it per run — while calm
    /// (1.0) and uneasy stay fixed. Pushing it higher makes individuals drive harder into a throat,
    /// where body compression and tangential friction can *drop* the collective flow: faster-is-slower.
    public static let panicArousal: Double = 1.5

    /// Desired-speed multiplier by arousal band (§2.6), with the panic band overridable per run so the
    /// faster-is-slower sweep (§6.5 G2) can drive it. Latent in S1; live from S2 once emotions update.
    public static func arousalFactor(_ emotion: EmotionalState, panic: Double = panicArousal) -> Double {
        switch emotion {
        case .calm: 1.0
        case .uneasy: uneasyArousal
        case .panicked: panic
        }
    }

    // Fire cellular automaton (§2.7) — time-compressed for a short demo; tunable, not citable.
    /// FIRE_SPREAD — base ignition rate to a neighbouring flammable cell, per second.
    public static let fireSpread: Double = 0.35
    /// IGNITION_DELAY — seconds a cell smoulders (igniting) before it burns and can spread.
    public static let ignitionDelay: Double = 1.0
    /// BURN_DURATION — seconds a cell burns before it is spent (burnt).
    public static let burnDuration: Double = 20.0
    /// FIRE_LETHAL_DELAY — seconds an agent survives in flame before injury turns fatal.
    public static let fireLethalDelay: Double = 2.0

    // Smoke diffusion field (§2.7) — outruns the flame; blinds but never blocks.
    /// SMOKE_PRODUCTION — opacity a burning cell adds per second.
    public static let smokeProduction: Double = 0.5
    /// SMOKE_DIFFUSION (D) — per-tick fraction of the gradient to a cell's neighbour mean it equalises.
    public static let smokeDiffusion: Double = 0.25
    /// SMOKE_DECAY — opacity lost per second as smoke thins.
    public static let smokeDecay: Double = 0.01

    // Hazard clock (§2.7)
    /// Fixed hazard tick — fire and smoke advance at 15 Hz, decoupled from the physics substep.
    public static let hazardStep: Double = 1.0 / 15.0
}
