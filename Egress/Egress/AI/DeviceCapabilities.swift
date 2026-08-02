import Foundation

#if EGRESS_FM_COACH && canImport(FoundationModels)
import FoundationModels
#endif

/// Whether the on-device Foundation model is usable on this device (§A.3). Drives the coach seam: when
/// this is `false`, the whole app runs on `CannedCoach` — a fully coherent experience, per the
/// §3.5.4 device-unsupported row.
///
/// The Foundation-model probe lives behind the `EGRESS_FM_COACH` build flag: the model path is
/// device- and Xcode-27-bound (the exact `@Generable`/`@Guide` spellings still need on-device
/// verification, §3.5.2), so by default it is compiled out and the app ships the canned coach only.
/// Define `EGRESS_FM_COACH` in the build settings once the model path has been verified on hardware.
enum DeviceCapabilities {
    static var supportsOnDeviceModel: Bool {
        #if EGRESS_FM_COACH && canImport(FoundationModels)
        if #available(iOS 26, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        return false
        #else
        return false
        #endif
    }
}
