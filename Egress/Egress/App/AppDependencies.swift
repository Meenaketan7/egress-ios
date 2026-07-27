import SwiftUI

/// The composition root: the single place the app's services are assembled and injected.
/// Hand-rolled DI — no framework. It grows as services land:
///   • persistence 
///   • simulation, intelligence, audio, haptics → build phase
struct AppDependencies {
    // Services will be added here, e.g.:
    // let venueStore: VenueStore
    // let makeSimulation: @Sendable (VenueModel, UInt64) -> Simulation

    /// The graph used by the running app.
    static func live() -> AppDependencies { AppDependencies() }

    /// A lightweight graph for previews and tests.
    static func preview() -> AppDependencies { AppDependencies() }
}

extension EnvironmentValues {
    /// Read anywhere via `@Environment(\.dependencies) private var deps`.
    @Entry var dependencies: AppDependencies = .preview()
}
