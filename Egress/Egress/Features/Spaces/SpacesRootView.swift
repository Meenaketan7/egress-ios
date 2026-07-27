import SwiftUI

/// Venue library (placeholder). Lists saved venues; entry to editor + simulation.
struct SpacesRootView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No Spaces Yet", app: .spaces)
            } description: {
                Text("Your saved venues will appear here.")
            }
            .navigationTitle("Spaces")
        }
    }
}

#Preview { SpacesRootView() }
