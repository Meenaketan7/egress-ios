import EgressEngine
import SwiftUI

/// The living canvas: `TimelineView(.animation)` ticks the controller once per display refresh,
/// and `Canvas` paints the current snapshot. This is the payoff of locking `SimulationSnapshot`
/// in S0 — swap `MockSimulation` for the real engine in the controller and not a line here moves.
struct SimCanvasView: View {
    let controller: SimulationController
    /// Overlay the colour-blind density textures (§5.6). Defaults on; the Simulate screen wires it to the
    /// user's Settings toggle.
    var patternFills: Bool = true

    var body: some View {
        TimelineView(.animation(paused: !controller.isRunning)) { timeline in
            let snapshot = controller.snapshot
            let venue = controller.venue
            Canvas { context, size in
                let projection = CanvasProjection(
                    worldWidth: venue.geometry.worldWidth,
                    worldHeight: venue.geometry.worldHeight,
                    viewSize: size
                )
                SimulationRenderer.draw(
                    snapshot,
                    venue: venue,
                    projection: projection,
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
