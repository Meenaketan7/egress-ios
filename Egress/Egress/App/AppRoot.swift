import SwiftUI

// MARK: - AppRoot

/// The app root: three tabs, each with its own navigation stack (A-02).
struct AppRoot: View {
    var body: some View {
        TabView {
            SpacesRootView()
                .tabItem { Label("Spaces", app: .spaces) }
            SimulateRootView()
                .tabItem { Label("Simulate", app: .simulate) }
            LearnRootView()
                .tabItem { Label("Learn", app: .learn) }
        }
        .tint(Color.egDataGreen) // the single accent
        #if DEBUG
            .touchIndicators() // recording aid; compiled out of release (§E.3)
        #endif
    }
}

// MARK: - CanvasHost

/// Hosts the simulation canvas + HUD, forced dark regardless of system appearance
/// (the canvas is dark even in Light Mode — design spec).
struct CanvasHost<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.egCanvasBase)
            .environment(\.colorScheme, .dark)
    }
}

#Preview {
    AppRoot().environment(\.dependencies, .preview())
}
