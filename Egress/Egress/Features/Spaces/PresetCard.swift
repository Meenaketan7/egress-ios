import EgressEngine
import SwiftUI

// MARK: - PresetCard

/// A gallery card for one furnished preset: a live mini-plan of the actual authored layout above the
/// venue's name and stats. The thumbnail reuses `VenueScenery` — the same drawing the editor and the
/// live sim use — so the card shows the real room the tap will load, not a stock illustration.
struct PresetCard: View {
    let preset: VenuePreset

    private var stats: String {
        let exits = preset.venue.exits.count
        return "\(Int(preset.widthMetres))×\(Int(preset.heightMetres)) m · "
            + "\(preset.crowd) people · \(exits) exit\(exits == 1 ? "" : "s")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EgressSpacing.xs) {
            PresetThumbnail(venue: preset.venue)
                .frame(height: 96)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle.egSquircle(EgressRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(preset.title)
                    .egBody(.headline)
                    .foregroundStyle(Color.egTextPrimary)
                Text(stats).egMicroLabel()
            }
            .padding(.horizontal, 2)
        }
        .frame(width: 190)
        .padding(EgressSpacing.sm)
        .egRaisedSurface(cornerRadius: EgressRadius.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(preset.title). \(stats). \(preset.blurb)")
    }
}

// MARK: - PresetThumbnail

/// A small top-down plan of a venue — room outline, props, walls and exits — drawn on the dark canvas.
/// The grid is omitted (too busy at thumbnail scale); everything else matches the full canvas exactly.
struct PresetThumbnail: View {
    let venue: VenueModel

    var body: some View {
        Canvas { context, size in
            let projection = CanvasProjection(
                worldWidth: venue.geometry.worldWidth,
                worldHeight: venue.geometry.worldHeight,
                viewSize: size, inset: 8
            )
            let topLeft = projection.point(Vec2(0, 0))
            let bottomRight = projection.point(Vec2(venue.geometry.worldWidth, venue.geometry.worldHeight))
            let room = CGRect(
                x: topLeft.x, y: topLeft.y,
                width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y
            )
            context.stroke(
                Path(roundedRect: room, cornerRadius: 4),
                with: .color(.egSeparator), lineWidth: 1
            )
            VenueScenery.drawObstacles(venue.obstacles, projection: projection, into: &context)
            VenueScenery.drawWalls(venue.walls, projection: projection, into: &context)
            VenueScenery.drawExits(venue.exits, projection: projection, into: &context)
        }
        .background(Color.egCanvasBase)
        .environment(\.colorScheme, .dark)
    }
}
