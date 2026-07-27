import SwiftData
import SwiftUI

// MARK: - AppDependencies

/// The composition root: the single place the app's services are assembled and injected.
/// Hand-rolled DI — no framework.
struct AppDependencies {
    /// Local, offline SwiftData store. Owned by the composition root.
    let modelContainer: ModelContainer

    // Future services: simulation, intelligence, audio, haptics.

    /// The running app's graph — a persistent, local-only store.
    static func live() -> AppDependencies {
        AppDependencies(modelContainer: makeContainer(inMemory: false))
    }

    /// Previews/tests — a shared in-memory store (never touches disk).
    static func preview() -> AppDependencies {
        AppDependencies(modelContainer: previewContainer)
    }

    /// One shared in-memory container, so repeated environment-default evaluation
    /// doesn't spin up multiple stores.
    private static let previewContainer: ModelContainer = makeContainer(inMemory: true)

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        let schema = Schema([RunRecord.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none // offline: no iCloud sync
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create the SwiftData store: \(error)")
        }
    }
}

extension EnvironmentValues {
    @Entry var dependencies: AppDependencies = .preview()
}
