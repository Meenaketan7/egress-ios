import EgressEngine

/// A hand-built venue for demoing the canvas before the Spaces editor exists (S2 replaces it
/// with user-authored venues). Deliberately simple — one open room, one exit — because the S0
/// `MockSimulation` doesn't avoid obstacles yet; furniture arrives when the real engine does.
enum SampleVenue {
    /// A 12 m × 9 m hall with a single 1.2 m exit centred on the far wall.
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
}