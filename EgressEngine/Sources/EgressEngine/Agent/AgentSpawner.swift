/// Deterministically populates a venue's free floor with people. Same geometry + same field +
/// same seed ⇒ identical spawn, which is what makes a demo run reproducible (build plan §A.4).
public enum AgentSpawner {
    /// The population mix sampled per agent — weighted by repetition: mostly adults, with a
    /// scatter of children, elderly, wheelchair users and staff.
    public static let defaultMix: [MobilityClass] = [
        .adult, .adult, .adult, .adult, .adult,
        .child, .elderly, .wheelchair, .staff
    ]

    /// Places `count` agents (capped at the number of free cells) on distinct reachable,
    /// non-exit cells. Reachability comes straight from the flow field, so no agent ever starts
    /// inside a wall or in a pocket cut off from every exit.
    public static func spawn(
        count: Int,
        in geometry: GridGeometry,
        field: FlowField,
        rng: inout SeededRNG,
        mix: [MobilityClass] = defaultMix
    ) -> [Agent] {
        guard count > 0, !mix.isEmpty else { return [] }

        var free: [GridCoord] = []
        free.reserveCapacity(geometry.size.count)
        for index in 0 ..< geometry.size.count {
            let cell = geometry.size.coord(atIndex: index)
            if field.isReachable(cell), field.cost(at: cell) > 0 { free.append(cell) }
        }
        free.shuffle(using: &rng)

        let placed = min(count, free.count)
        return (0 ..< placed).map { id in
            let mobility = mix.randomElement(using: &rng) ?? .adult
            return Agent(id: id, position: geometry.worldCenter(of: free[id]), mobility: mobility)
        }
    }
}
