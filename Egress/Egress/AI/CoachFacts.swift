import EgressEngine
import Foundation

/// The engine numbers the coach is allowed to cite, pulled from a finished run and pre-formatted once so
/// the canned prose and the model's number-substitution both read from the *same* grounded source
/// (§3.5.2 anti-hallucination). Nothing here is invented — every field traces to `Metrics`/`Verdict` or
/// a `SafetyStandards` constant.
struct CoachFacts: Equatable {
    let clearance: Int          // seconds to clear, rounded
    let target: Int             // clearance target for this venue type, seconds
    let cap: Int                // the run's time cap, seconds
    let peakDensity: Double     // worst smoothed density, p·m⁻²
    let peakLocation: String    // human phrase, e.g. "near Exit 0"
    let atRiskPct: Int          // % of the crowd that spent too long in the at-risk band
    let dwell: Int              // at-risk dwell threshold, seconds
    let casualties: Int
    let trapped: Int
    let occupancy: Int
    let cautionBand: Double     // the caution density band, p·m⁻² (5.0)
    let score: Int
    let venueName: String

    init(result: RunResult, venue: VenueModel) {
        let m = result.metrics
        clearance = Int(m.clearance.rounded())
        target = Int(m.clearanceTarget.rounded())
        cap = Int(m.timeCap.rounded())
        peakDensity = (m.peakDensity * 10).rounded() / 10
        atRiskPct = Int((m.atRiskFraction * 100).rounded())
        dwell = Int(SimConstants.atRiskDwell.rounded())
        casualties = m.casualties
        trapped = m.trappedCount
        occupancy = m.spawnedCount
        cautionBand = SafetyStandards.densityAtRisk
        score = result.score.value
        venueName = venue.name
        peakLocation = Self.locate(m.peakLocation, in: venue)
    }

    /// Formatted density with its unit, e.g. "5.4 p·m⁻²".
    var peakDensityText: String { String(format: "%.1f p·m⁻²", peakDensity) }
    /// The caution band with its unit.
    var cautionBandText: String { String(format: "%.1f p·m⁻²", cautionBand) }

    /// Turn the worst-density cell into a phrase relative to the nearest exit — grounded, but readable
    /// ("near Exit 0"), not a raw grid coordinate. Falls back gracefully when there's no peak or no exit.
    private static func locate(_ cell: GridCoord?, in venue: VenueModel) -> String {
        guard let cell else { return "on the floor" }
        let point = venue.geometry.worldCenter(of: cell)
        guard let nearest = venue.exits.min(by: {
            $0.center.distance(to: point) < $1.center.distance(to: point)
        }) else {
            return "on the floor"
        }
        return venue.exits.count == 1 ? "at the exit" : "near Exit \(nearest.id)"
    }
}
