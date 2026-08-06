import EgressEngine
import SwiftUI

/// The living canvas: `TimelineView(.animation)` ticks the controller once per display refresh,
/// and `Canvas` paints the current snapshot. This is the payoff of locking `SimulationSnapshot`
/// in S0 — swap `MockSimulation` for the real engine in the controller and not a line here moves.
///
/// The floor is drawn through the controller's pan/zoom `camera`, and a transparent `SimCanvasInputView`
/// on top turns drags, pinches and taps into camera moves — so you can zoom into the crowd to read faces
/// and tap a person to follow them. The camera fits the whole venue until the first gesture or button.
struct SimCanvasView: View {
    let controller: SimulationController
    /// Overlay the colour-blind density textures (§5.6). Defaults on; the Simulate screen wires it to the
    /// user's Settings toggle.
    var patternFills: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                TimelineView(.animation(paused: !controller.isRunning)) { timeline in
                    let snapshot = controller.displaySnapshot
                    let venue = controller.venue
                    Canvas { context, canvasSize in
                        SimulationRenderer.draw(
                            snapshot,
                            venue: venue,
                            projection: projection(for: canvasSize),
                            patternFills: patternFills,
                            into: &context
                        )
                    }
                    .onChange(of: timeline.date) { _, frame in
                        controller.advance(to: frame)
                    }
                    // §5.6: 200 agents are one accessibility element, not 200. The label names the venue; the
                    // value carries the live readout VoiceOver re-reads on demand.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Simulation canvas, \(venue.name)")
                    .accessibilityValue(Self.summary(snapshot.live))
                    .accessibilityAddTraits(.updatesFrequently)
                }
                // Camera gestures — pan / pinch / tap-to-follow. Kept above the canvas; the overlay buttons
                // (added by the Simulate screen) still sit above this and win their own taps.
                SimCanvasInputView(controller: controller)
            }
            .onAppear { controller.noteCanvasSize(size) }
            .onChange(of: size) { _, newSize in controller.noteCanvasSize(newSize) }
        }
    }

    /// World→screen mapping for this frame: the pan/zoom camera once it has been framed, otherwise a
    /// one-off fit-to-view (identical framing) for the very first render before `noteCanvasSize` runs.
    private func projection(for size: CGSize) -> CanvasProjection {
        if controller.cameraFramed {
            return CanvasProjection(camera: controller.camera, viewSize: size)
        }
        return CanvasProjection(
            worldWidth: controller.venue.geometry.worldWidth,
            worldHeight: controller.venue.geometry.worldHeight,
            viewSize: size
        )
    }

    /// The spoken live summary (§5.6) — occupants, elapsed time, evacuated fraction, peak density, and
    /// casualties only once there are any. Peak *location* is an end-of-run metric, so it is not claimed
    /// here rather than spoken inaccurately.
    private static func summary(_ live: LiveMetrics) -> String {
        let occupants = live.activeCount + live.evacuatedCount + live.casualtyCount
        let pct = Int((live.fractionOut * 100).rounded())
        var parts = [
            "\(occupants) occupants",
            "\(Int(live.elapsed.rounded())) seconds elapsed",
            "\(pct)% evacuated",
            "peak density \(String(format: "%.1f", live.worstDensity)) persons per square metre"
        ]
        if live.casualtyCount > 0 {
            parts.append("\(live.casualtyCount) casualties")
        }
        return parts.joined(separator: ", ") + "."
    }
}
