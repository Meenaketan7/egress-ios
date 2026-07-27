import Foundation
import SwiftData
import EgressEngine

/// A saved simulation run — the persisted result record.
/// Stores stable primitives (not domain enums) so old records keep loading
/// if the engine's types evolve.
@Model
final class RunRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var venueName: String
    var venueTypeRaw: String     // VenueType.rawValue — stored as a stable primitive
    var score: Int               // 0…100 safety score
    var verdictRaw: String       // "pass" / "warn" / "fail" (bridged when the Verdict domain lands)
    var clearanceTime: Double    // seconds to clear
    var occupancy: Int
    var seed: String             // RNG seed for exact reproduction (String avoids UInt64/Int64 limits)

    init(
        id: UUID = UUID(),
        date: Date = .now,
        venueName: String,
        venueTypeRaw: String,
        score: Int,
        verdictRaw: String,
        clearanceTime: Double,
        occupancy: Int,
        seed: String
    ) {
        self.id = id
        self.date = date
        self.venueName = venueName
        self.venueTypeRaw = venueTypeRaw
        self.score = score
        self.verdictRaw = verdictRaw
        self.clearanceTime = clearanceTime
        self.occupancy = occupancy
        self.seed = seed
    }

    /// Convenience bridge back to the domain enum (nil if the stored value is unknown).
    var venueType: VenueType? { VenueType(rawValue: venueTypeRaw) }
}
