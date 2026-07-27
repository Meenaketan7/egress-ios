import SwiftUI

/// Simulation host (placeholder). The dark canvas + HUD live here.
struct SimulateRootView: View {
    var body: some View {
        NavigationStack {
            CanvasHost {
                VStack(spacing: EgressSpacing.lg) {
                    Text("Canvas").egDisplay().foregroundStyle(Color.egTextTertiary)

                    HStack(spacing: EgressSpacing.md) {
                        VStack(alignment: .leading, spacing: EgressSpacing.xxs) {
                            Text("Occupancy").egMicroLabel()
                            Text("000").egData(.title2).foregroundStyle(Color.egDataGreen)
                        }
                        VStack(alignment: .leading, spacing: EgressSpacing.xxs) {
                            Text("Clear Time").egMicroLabel()
                            Text("0.0s").egData(.title2).foregroundStyle(Color.egTextPrimary)
                        }
                    }
                    .padding(EgressSpacing.md)
                    .egGlassSurface()
                }
            }
            .navigationTitle("Simulate")
        }
    }
}

#Preview { SimulateRootView() }
