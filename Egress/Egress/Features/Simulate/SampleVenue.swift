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
}
