import SwiftUI

struct ContentView: View {
    private let swatches: [(String, Color)] = [
        ("canvas", .egCanvasBase), ("raised", .egSurfaceRaised),
        ("green", .egDataGreen),   ("cyan", .egCyan),
        ("warn", .egVerdictWarn),  ("fail", .egVerdictFail),
        ("staff", .egAgentStaff),  ("flood", .egHazardFlood)
    ]
    private let cols = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EgressSpacing.xl) {
                Text("Egress").egDisplay(width: .compressed)
                    .foregroundStyle(Color.egTextPrimary)

                VStack(alignment: .leading, spacing: EgressSpacing.xs) {
                    Text("Capacity").egMicroLabel()
                    Text("200").egData(.largeTitle).foregroundStyle(Color.egDataGreen)
                }

                Text("A verdict reason a human reads, in SF Pro Text.")
                    .egBody().foregroundStyle(Color.egTextSecondary)

                LazyVGrid(columns: cols, spacing: EgressSpacing.sm) {
                    ForEach(swatches, id: \.0) { name, color in
                        VStack(spacing: EgressSpacing.xxs) {
                            RoundedRectangle.egSquircle(EgressRadius.sm)
                                .fill(color).frame(height: 48)
                                .overlay(RoundedRectangle.egSquircle(EgressRadius.sm)
                                    .stroke(Color.egSeparator, lineWidth: 1))
                            Text(name).egMicroLabel()
                        }
                    }
                }
            }
            .padding(EgressSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.egCanvasBase)
    }
}

#Preview { ContentView().preferredColorScheme(.dark) }