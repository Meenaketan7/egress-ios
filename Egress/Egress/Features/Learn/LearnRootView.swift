import SwiftUI

/// Learn tab (placeholder). Articles, case studies, and quizzes.
struct LearnRootView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Learn", app: .learn)
            } description: {
                Text("Guides, case studies, and quizzes will appear here.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.egGround)
            .navigationTitle("Learn")
        }
    }
}

#Preview { LearnRootView() }
