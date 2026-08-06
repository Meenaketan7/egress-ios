import EgressEngine
import SwiftUI

// MARK: - LearnRootView

/// The Learn tab (design: the Learn screenshot). A cream home screen carrying the daily quiz, a
/// preparedness-tips shelf, and the case-study list — each case study pushes a detail screen, and a
/// *playable* one launches its scenario in the editor/sim. Dressed in the app's pixel chrome: a pink
/// pixel-bordered quiz card, chunky-bordered row icons, and the pixel game-screen thumbnail on the detail.
/// Presented without a nav bar — the big serif header *is* the chrome — matching the Spaces tab.
struct LearnRootView: View {
    /// Launches a playable case study — opens the editor cover seeded with its preset (owned by `AppRoot`,
    /// exactly the path the Spaces preset cards use).
    let onPlay: (VenuePreset) -> Void

    @Environment(FeedbackServices.self)
    private var feedback: FeedbackServices?
    /// The settings sheet, raised from the header menu.
    @State private var showSettings = false
    /// The Daily Quiz game, raised full-screen from the quiz card's Start button.
    @State private var showQuiz = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EgressSpacing.lg) {
                    header

                    QuizCard(prompt: LearnLibrary.dailyQuiz) {
                        feedback?.haptics.play(.toolTap)
                        showQuiz = true
                    }
                    .padding(.top, EgressSpacing.xs)

                    Text("Case studies")
                        .font(.system(.footnote, weight: .heavy))
                        .fontWidth(.condensed)
                        .textCase(.uppercase)
                        .tracking(1.4)
                        .foregroundStyle(Color.egTextTertiary)
                        .padding(.top, EgressSpacing.sm)

                    ForEach(Array(LearnLibrary.caseStudies.enumerated()), id: \.element.id) { index, study in
                        if index > 0 { rowDivider }
                        NavigationLink(value: study) {
                            LearnRow(
                                icon: .square(symbol: "book", tint: .egTextPrimary),
                                title: study.rowTitle,
                                subtitle: study.rowSubtitle
                            )
                        }
                        .buttonStyle(RowPress())
                    }
                }
                .padding(.horizontal, EgressSpacing.lg)
                .padding(.top, EgressSpacing.sm)
                .padding(.bottom, EgressSpacing.xl)
            }
            .background(Color.egGround)
            .scrollIndicators(.hidden)
            .navigationDestination(for: CaseStudy.self) { study in
                CaseStudyDetailView(study: study, onPlay: onPlay)
            }
            .sheet(isPresented: $showSettings) { SettingsSheet() }
            .fullScreenCover(isPresented: $showQuiz) { QuizGameView() }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Learn")
                .font(.system(size: 34, weight: .black, design: .serif))
                .foregroundStyle(Color.egTextPrimary)

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Color.egTextPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Menu")
        }
        .padding(.top, EgressSpacing.sm)
    }

    /// The tan hairline between shelf rows.
    private var rowDivider: some View {
        Rectangle()
            .fill(Color.egSeparator)
            .frame(height: 1)
    }
}

// MARK: - QuizCard

/// The daily-quiz card — a soft-pink pixel-bordered panel with the coin badge, the letter-spaced label,
/// the serif question, and the green Start button (design: the Learn screenshot).
private struct QuizCard: View {
    let prompt: QuizPrompt
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EgressSpacing.md) {
            HStack(spacing: EgressSpacing.sm) {
                coin
                Text("Daily quiz")
                    .font(.system(.caption, weight: .heavy))
                    .fontWidth(.condensed)
                    .textCase(.uppercase)
                    .tracking(1.3)
                    .foregroundStyle(Color.egTextSecondary)
            }

            Text(prompt.question)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(Color.egTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onStart) {
                Text("Start")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(Color.egTextPrimary)
                    .padding(.horizontal, EgressSpacing.xl)
                    .padding(.vertical, EgressSpacing.sm)
                    .background(PixelCornerRect(radius: EgressRadius.sm, pixel: 3).fill(Color.egDataGreen))
                    .overlay(PixelCornerRect(radius: EgressRadius.sm, pixel: 3).strokeBorder(Color.egOutline, lineWidth: 1.5))
            }
            .buttonStyle(RowPress())
            .padding(.top, EgressSpacing.xs)
        }
        .padding(EgressSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PixelCornerRect(radius: EgressRadius.lg, pixel: 5).fill(Color.egAccentPink.opacity(0.32)))
        .overlay(PixelCornerRect(radius: EgressRadius.lg, pixel: 5).strokeBorder(Color.egOutline, lineWidth: 2.5))
    }

    /// A little gold coin — a filled disc, its charcoal ring, and a centre pip.
    private var coin: some View {
        ZStack {
            Circle().fill(Color.egAccentGold)
            Circle().strokeBorder(Color.egOutline, lineWidth: 1.5)
            Circle().fill(Color.egOutline).frame(width: 5, height: 5)
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - LearnRow

/// A shelf row: a bordered icon, a bold title over a quiet subtitle, and a trailing chevron
/// (design: the Learn list rows). Used for the tips shelf and each case study.
struct LearnRow: View {
    /// The leading icon — a bordered circle (tips) or a bordered pixel square (case study).
    enum Icon {
        case circle(symbol: String, tint: Color)
        case square(symbol: String, tint: Color)
    }

    let icon: Icon
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: EgressSpacing.md) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.egTextPrimary)
                Text(subtitle)
                    .egBody(.subheadline)
                    .foregroundStyle(Color.egTextSecondary)
            }

            Spacer(minLength: EgressSpacing.sm)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.egTextTertiary)
        }
        .padding(.vertical, EgressSpacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case let .circle(symbol, tint):
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.egSurfaceRaised))
                .overlay(Circle().strokeBorder(Color.egOutline, lineWidth: 2))
        case let .square(symbol, tint):
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(PixelCornerRect(radius: EgressRadius.xs, pixel: 2).fill(Color.egSurfaceRaised))
                .overlay(PixelCornerRect(radius: EgressRadius.xs, pixel: 2).strokeBorder(Color.egOutline, lineWidth: 2))
        }
    }
}

// MARK: - RowPress

/// A gentle press for the shelf rows and small buttons — a slight dip and dim, like the gallery cards.
struct RowPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Motion.tap, value: configuration.isPressed)
    }
}

#Preview {
    LearnRootView(onPlay: { _ in })
        .environment(\.dependencies, .preview())
}
