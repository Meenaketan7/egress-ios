import SwiftData
import SwiftUI

@main
struct EgressApp: App {
    private let dependencies = AppDependencies.live()
    /// The audio + haptic + settings channels, created once and shared through the environment.
    @State private var feedback = FeedbackServices()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(\.dependencies, dependencies)
                .environment(feedback)
                .modelContainer(dependencies.modelContainer)
        }
        .onChange(of: scenePhase) { _, phase in feedback.handle(phase) }
    }
}
