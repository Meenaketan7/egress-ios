import EgressEngine
import SwiftUI

// MARK: - PresetCard

/// A gallery card for one furnished preset (design: the Spaces carousel). A live mini-plan of the real
/// authored layout — the same `VenueScenery` drawing the editor and sim use — with the venue's resident
/// character standing on it and a difficulty *tier* badge in the corner, above the name and a three-up
/// CAPACITY · EXITS · DIFFICULTY stat row. Tapping loads exactly the room shown.
struct PresetCard: View {
    let preset: VenuePreset

    /// 1…3 — crowd pressure per exit, mapped to the difficulty dots and the tier badge.
    private var difficulty: Int {
        let perExit = Double(preset.crowd) / Double(max(1, preset.venue.exits.count))
        switch perExit {
        case ..<40: return 1
        case ..<80: return 2
        default: return 3
        }
    }

    /// The corner badge — a difficulty tier the way the mockup tags its cards (LITE · STD · PRO), lit up
    /// like a neon sign: bright pixel text and border glowing against the dark thumbnail.
    private var tier: (label: String, color: Color) {
        switch difficulty {
        case 1: ("LITE", Color(hex: 0x3FE0D0)) // neon cyan
        case 2: ("STD", Color(hex: 0xF5B53D))  // neon amber
        default: ("PRO", Color(hex: 0xE44FC4)) // neon magenta
        }
    }

    /// The character who "lives" in this venue — one of the bundled pixel-art residents, picked from the
    /// preset's stable seed so a card keeps the same person across launches and never re-rolls on redraw.
    private var residentSprite: String {
        "sprite_\(preset.id.pixelSeed % PresetCard.residentCount + 1)"
    }

    /// How many `sprite_1…N` character images ship in the asset catalog (Assets.xcassets).
    private static let residentCount = 31

    var body: some View {
        VStack(alignment: .leading, spacing: EgressSpacing.md) {
            // One brown "screen": the room plan on the left, the resident and its tier badge in a column
            // on the right — both sit on the same dark canvas inside a single pixel border (design request).
            HStack(alignment: .top, spacing: EgressSpacing.sm) {
                PresetThumbnail(venue: preset.venue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .trailing, spacing: EgressSpacing.xs) {
                    tierBadge
                    Spacer(minLength: 0)
                    Image(residentSprite)
                        .resizable()
                        .interpolation(.none) // keep the pixel edges crisp when scaled
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 92)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 118)
            .padding(EgressSpacing.sm)
            .background(Color.egCanvasBase)
            .clipShape(PixelCornerRect(radius: EgressRadius.sm, pixel: 3))
            .overlay(
                PixelCornerRect(radius: EgressRadius.sm, pixel: 3)
                    .strokeBorder(Color.egOutline, lineWidth: 1.5)
            )

            Text(preset.title)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(Color.egTextPrimary)

            statsRow
        }
        .frame(width: 224)
        .padding(EgressSpacing.md)
        .egPixelSurface(radius: EgressRadius.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(preset.title). \(preset.crowd) capacity, \(preset.venue.exits.count) exits, difficulty \(difficulty) of 3. \(preset.blurb)")
    }

    // MARK: Pieces

    private var tierBadge: some View {
        PixelText(text: tier.label, pixel: 1.7, color: tier.color)
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(PixelCornerRect(radius: 5, pixel: 2).fill(Color.black.opacity(0.3)))
            .overlay(PixelCornerRect(radius: 5, pixel: 2).strokeBorder(tier.color, lineWidth: 1.2))
            .shadow(color: tier.color.opacity(0.9), radius: 3) // neon glow
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: EgressSpacing.sm) {
            stat("Capacity", "\(preset.crowd)")
            Spacer(minLength: 0)
            stat("Exits", "\(preset.venue.exits.count)")
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 3) {
                Text("Difficulty").egMicroLabel()
                difficultyDots
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).egMicroLabel()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.egTextPrimary)
        }
    }

    private var difficultyDots: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { i in
                Circle()
                    .fill(i < difficulty ? Color.egTextPrimary : Color.clear)
                    .overlay(Circle().strokeBorder(Color.egTextTertiary, lineWidth: 1))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.top, 2)
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
