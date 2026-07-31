import EgressEngine
import SwiftUI

/// Simulation host — owns the run and shows the live canvas, HUD and transport controls.
struct SimulateRootView: View {
    @State private var controller = SimulationController(
        venue: SampleVenue.hall(),
        config: SimulationConfig(agentCount: 120, maxValidatedAgents: 200, seed: 42)
    )

    var body: some View {
        NavigationStack {
            CanvasHost {
                VStack(spacing: EgressSpacing.md) {
                    SimCanvasView(controller: controller)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    hud
                    controls
                }
                .padding(EgressSpacing.md)
            }
            .navigationTitle("Simulate")
        }
    }

    private var hud: some View {
        HStack(spacing: EgressSpacing.xl) {
            metric("Inside", "\(controller.snapshot.live.activeCount)", .egDataGreen)
            metric("Elapsed", String(format: "%.1fs", controller.snapshot.live.elapsed), .egTextPrimary)
            metric("Out", String(format: "%.0f%%", controller.snapshot.live.fractionOut * 100), .egCyan)
        }
        .padding(EgressSpacing.md)
        .frame(maxWidth: .infinity)
        .egGlassSurface()
    }

    private func metric(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: EgressSpacing.xxs) {
            Text(label).egMicroLabel()
            Text(value).egData(.title2).foregroundStyle(tint)
        }
    }

    private var controls: some View {
        HStack(spacing: EgressSpacing.md) {
            Button {
                controller.isRunning ? controller.pause() : controller.play()
            } label: {
                Label(controller.isRunning ? "Pause" : "Play",
                      systemImage: controller.isRunning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                controller.reset()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
        }
        .tint(.egDataGreen)
    }
}

#Preview {
    SimulateRootView()
}