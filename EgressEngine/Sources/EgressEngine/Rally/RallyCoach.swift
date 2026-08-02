/// The grounded half of RALLY (§3.4) — picks the single highest-impact *feasible* geometry fix for a
/// run that fell short, with no AI in the loop. The demo's honest fallback: the app's on-device model
/// dresses this in prose, but the fix itself (which element, what new measurement) is chosen here from
/// the verdict and the jam location, so every suggestion is engine-grounded and reproducible.
public struct RallyCoach: Sendable {
    public static let `default` = RallyCoach()
    public init() {}

    /// The fix to offer, or `nil` when the run already passed (nothing to fix) or no feasible fix fits.
    /// The bottleneck is almost always exit capacity, so the fix widens the exit nearest the worst jam
    /// to at least the citable exit minimum — and wider than it is now.
    public func suggest(for verdict: Verdict, metrics: Metrics, in venue: VenueModel) -> Fix? {
        guard verdict.level != .pass else { return nil }
        guard let exit = jammedExit(in: venue, near: metrics.peakLocation) else { return nil }
        let desired = max(SafetyStandards.minExitWidth, exit.width + 0.7)
        for width in [desired, SafetyStandards.minExitWidth] {
            let fix = Fix.widenExit(id: exit.id, width: width)
            if fix.feasibility(in: venue).isFeasible { return fix }
        }
        return nil
    }

    /// The exit to widen: the one nearest the worst jam, or — with no recorded jam — the narrowest door.
    private func jammedExit(in venue: VenueModel, near peak: GridCoord?) -> Exit? {
        guard !venue.exits.isEmpty else { return nil }
        guard let peak else { return venue.exits.min { $0.width < $1.width } }
        let cellSize = venue.geometry.cellSize
        let jam = Vec2((Double(peak.x) + 0.5) * cellSize, (Double(peak.y) + 0.5) * cellSize)
        return venue.exits.min { $0.center.distance(to: jam) < $1.center.distance(to: jam) }
    }
}
