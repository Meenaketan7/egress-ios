import SwiftUI
import SwiftData

@main
struct EgressApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(\.dependencies, dependencies)
                .modelContainer(dependencies.modelContainer)
        }
    }
}