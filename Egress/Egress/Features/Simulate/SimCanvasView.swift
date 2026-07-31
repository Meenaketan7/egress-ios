import EgressEngine
import SwiftUI

/// The living canvas: `TimelineView(.animation)` ticks the controller once per display refresh,
/// and `Canvas` paints the current snapshot. This is the payoff of locking `SimulationSnapshot`
/// in S0 — swap `MockSimulation` for the real engine in the controller and not a line here moves.
struct SimCanvasView: View {
    let controller: SimulationController

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
                SimulationRenderer.draw(snapshot, venue: venue, projection: projection, into: &context)
            }
            .onChange(of: timeline.date) { _, frame in
                controller.advance(to: frame)
            }
        }
    }
}