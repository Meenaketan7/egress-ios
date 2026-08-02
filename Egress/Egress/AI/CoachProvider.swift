import EgressEngine
import Foundation

/// Chooses the coach for this device and always returns grounded advice. When the on-device model is
/// available it is tried first — and it internally falls back to the canned coach on any validation
/// failure or timeout (§3.5.3) — so the results card can never be left empty. On an unsupported device
/// (or with the model path compiled out) the canned coach answers directly.
@MainActor
struct CoachProvider {
    static let shared = CoachProvider()

    private let canned = CannedCoach()

    func advise(for result: RunResult, venue: VenueModel) async -> CoachAdvice {
        #if EGRESS_FM_COACH && canImport(FoundationModels)
        if DeviceCapabilities.supportsOnDeviceModel {
            return await FoundationModelsCoach(fallback: canned).advise(for: result, venue: venue)
        }
        #endif
        return await canned.advise(for: result, venue: venue)
    }
}
