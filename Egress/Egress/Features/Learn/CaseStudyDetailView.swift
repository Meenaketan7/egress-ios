import EgressEngine
import SwiftUI

// MARK: - CaseStudyDetailView

/// A case study's detail screen (design: the two case-study screenshots). One layout, two shapes:
/// a **fictional** study shows the pixel game-screen thumbnail with a difficulty badge and a pinned
/// "Play this scenario" button; a **real incident** shows an attribution line, a rule, the prose, and a
/// quiet sourcing footer — no thumbnail, no play. Its own pixel back button stands in for the nav bar.
struct CaseStudyDetailView: View {
    let study: CaseStudy
    /// Launches the scenario — set by `LearnRootView`, plumbed from `AppRoot`.
    let onPlay: (VenuePreset) -> Void

    @Environment(\.dismiss)
    private var dismiss
    @Environment(FeedbackServices.self)
    private var feedback: FeedbackServices?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EgressSpacing.lg) {
                header

                if let preset = study.preset {
                    thumbnail(preset)
                        .padding(.bottom, EgressSpacing.xs)
                }

                Text(study.detailTitle)
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(Color.egTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let attribution = study.attribution {
                    Text(attribution)
                        .egBody(.subheadline)
                        .foregroundStyle(Color.egTextTertiary)
                    Rectangle()
                        .fill(Color.egOutline)
                        .frame(height: 1.5)
                        .padding(.vertical, EgressSpacing.xs)
                }

                ForEach(Array(study.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .egBody(.body)
                        .foregroundStyle(Color.egTextSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let note = study.sourceNote {
                    Text(note)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.egTextTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, EgressSpacing.xl)
                }
            }
            .padding(.horizontal, EgressSpacing.lg)
            .padding(.top, EgressSpacing.sm)
            .padding(.bottom, EgressSpacing.xl)
        }
        .background(Color.egGround)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            if let preset = study.preset { playButton(preset) }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar() // full-bleed reading view — let the Play button reach the screen edge
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: EgressSpacing.md) {
            Button {
                feedback?.haptics.play(.toolTap)
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.egTextPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.egSurfaceRaised))
                    .overlay(Circle().strokeBorder(Color.egOutline, lineWidth: 2))
            }
            .buttonStyle(RowPress())
            .accessibilityLabel("Back")

            Text(study.kind.eyebrow)
                .font(.system(.footnote, weight: .heavy))
                .fontWidth(.condensed)
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(Color.egTextTertiary)

            Spacer(minLength: 0)
        }
        .padding(.top, EgressSpacing.sm)
    }

    // MARK: Thumbnail (fictional / playable only)

    /// The pixel game-screen preview: the venue's live mini-plan on the dark canvas, sitting on a cream
    /// card over a gold "dune", with the DIFFICULTY badge cresting the bottom edge.
    private func thumbnail(_ preset: VenuePreset) -> some View {
        ZStack(alignment: .bottom) {
            PresetThumbnail(venue: preset.venue)
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipShape(PixelCornerRect(radius: EgressRadius.sm, pixel: 3))
                .overlay(PixelCornerRect(radius: EgressRadius.sm, pixel: 3).strokeBorder(Color.egOutline, lineWidth: 1.5))
                .padding(EgressSpacing.md)
                .padding(.bottom, EgressSpacing.sm)

            difficultyBadge
                .offset(y: -EgressSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .background(
            PixelCornerRect(radius: EgressRadius.lg, pixel: 4)
                .fill(Color.egSurfaceRaised)
                .overlay(alignment: .bottom) {
                    // A warm gold dune peeking from behind the screen — the reference's flourish.
                    Ellipse()
                        .fill(Color.egAccentGold.opacity(0.85))
                        .frame(height: 70)
                        .offset(y: 34)
                }
                .clipShape(PixelCornerRect(radius: EgressRadius.lg, pixel: 4))
        )
        .overlay(PixelCornerRect(radius: EgressRadius.lg, pixel: 4).strokeBorder(Color.egOutline, lineWidth: 2))
    }

    /// The white pixel-bordered "DIFFICULTY ● ● ○" pill overlaid on the thumbnail.
    private var difficultyBadge: some View {
        HStack(spacing: EgressSpacing.sm) {
            Text("Difficulty")
                .font(.system(.caption2, weight: .heavy))
                .fontWidth(.condensed)
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(Color.egTextSecondary)

            HStack(spacing: 4) {
                ForEach(0 ..< 3, id: \.self) { i in
                    Circle()
                        .fill(i < study.difficulty ? Color.egTextPrimary : Color.clear)
                        .overlay(Circle().strokeBorder(Color.egTextPrimary, lineWidth: 1.2))
                        .frame(width: 7, height: 7)
                }
            }
        }
        .padding(.horizontal, EgressSpacing.md)
        .padding(.vertical, EgressSpacing.sm)
        .background(PixelCornerRect(radius: 14, pixel: 3).fill(Color.egSurfaceRaised))
        .overlay(PixelCornerRect(radius: 14, pixel: 3).strokeBorder(Color.egOutline, lineWidth: 1.5))
    }

    // MARK: Play button (fictional / playable only)

    private func playButton(_ preset: VenuePreset) -> some View {
        Button {
            feedback?.haptics.play(.toolTap)
            onPlay(preset)
        } label: {
            HStack(spacing: EgressSpacing.sm) {
                Image(app: .play)
                    .font(.system(size: 15, weight: .heavy))
                Text("Play this scenario")
                    .font(EgressFont.body(.headline, weight: .heavy))
            }
            .foregroundStyle(Color.egTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, EgressSpacing.lg)
            .background(
                RoundedRectangle.egSquircle(EgressRadius.md)
                    .fill(Color.egDataGreen)
                    .overlay(alignment: .bottom) {
                        RoundedRectangle.egSquircle(EgressRadius.md)
                            .fill(Color.egDataGreenDeep)
                            .frame(height: 5)
                            .padding(.horizontal, 2)
                    }
                    .clipShape(RoundedRectangle.egSquircle(EgressRadius.md))
            )
            .overlay(RoundedRectangle.egSquircle(EgressRadius.md).strokeBorder(Color.egOutline, lineWidth: 2))
        }
        .buttonStyle(RowPress())
        .padding(.horizontal, EgressSpacing.lg)
        .padding(.bottom, EgressSpacing.sm)
        .accessibilityHint("Opens the editor seeded with this scenario")
    }
}

#Preview("Fictional") {
    NavigationStack {
        CaseStudyDetailView(study: LearnLibrary.atrium, onPlay: { _ in })
    }
    .environment(\.dependencies, .preview())
}

#Preview("Real incident") {
    NavigationStack {
        CaseStudyDetailView(study: LearnLibrary.stationPlatform, onPlay: { _ in })
    }
    .environment(\.dependencies, .preview())
}
