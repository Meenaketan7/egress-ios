import EgressEngine

/// Hand-built venues for the Simulate tab's default demo (the Spaces editor now produces user-authored
/// venues too). Wall-less on purpose — the bottleneck here is a single tight exit on an open room
/// rather than a walled throat, which keeps the demo's failing layout easy to read at a glance.
enum SampleVenue {
    /// A 12 m × 9 m hall with a single 1.2 m exit centred on the far wall — a comfortable PASS baseline.
    static func hall() -> VenueModel {
        let geometry = GridGeometry(size: GridSize(width: 48, height: 36)) // 0.25 m cells → 12 m × 9 m
        let exit = Exit(id: 0, a: Vec2(5.4, 9), b: Vec2(6.6, 9))
        return VenueModel(
            id: 0,
            name: "Community Hall",
            type: .concertHall,
            geometry: geometry,
            exits: [exit]
        )
    }

    /// A packed 11 m × 8 m nightclub draining through a single 1.0 m door — the demo's *failing* layout:
    /// the crowd overruns the egress target and packs the doorway, so the run lands a WARN/FAIL and RALLY
    /// has a real fix to offer (widen the exit). The core-journey fixture for the results money-shot.
    static func crowdedClub() -> VenueModel {
        let geometry = GridGeometry(size: GridSize(width: 44, height: 32)) // 11 m × 8 m
        let exit = Exit(id: 0, a: Vec2(5.0, 8), b: Vec2(6.0, 8)) // 1.0 m, centred on the far wall
        return VenueModel(
            id: 0,
            name: "The Vault",
            type: .nightclub,
            geometry: geometry,
            exits: [exit]
        )
    }

    /// The Simulate-tab **money shot**: the furnished Vault (single 1.0 m door, bar + stage) with a fire
    /// seeded in the exit queue. The single door bottlenecks the crowd right as the fire spreads through
    /// it → casualties → a guaranteed FAIL (verdict rule 1). RALLY's fix widens that door, so the crowd
    /// clears before the fire reaches them → fewer casualties and a better verdict on Apply & re-run.
    /// Tuned empirically (`MoneyShotExperiment`) for a reliable, dramatic FAIL → fix arc.
    static func moneyShotDemo() -> (VenueModel, SimulationConfig) {
        let preset = VenuePreset.catalog.first { $0.id == "nightclub" } ?? VenuePreset.catalog[0]
        let venue = preset.venue
        let config = SimulationConfig(
            agentCount: moneyShotCrowd,
            maxValidatedAgents: 300,
            seed: 42,
            ignition: moneyShotIgnition
        )
        return (venue, config)
    }

    /// Money-shot crowd + ignition, kept as named constants so the tuning is legible and adjustable.
    /// Tuned in `MoneyShotExperiment`: 150 people with the fire seeded in the exit queue at (5.5, 6.0)
    /// yields ~55 casualties (FAIL); the coach's widen-to-1.7 m fix clears the queue faster and roughly
    /// halves the toll (~32), the "fewer casualties after the fix" payoff.
    static let moneyShotCrowd = 150
    static let moneyShotIgnition = [Vec2(5.5, 6.0)]
}
