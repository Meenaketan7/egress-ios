import SwiftUI

// MARK: - QuizGameView

/// The Daily Quiz game screen (design: the quiz screenshot). One screen, two live states driven by
/// `QuizGameModel.phase`: **answering** shows the stat row, progress, RALLY's speech bubble and the
/// options with a radio selection; **revealing** swaps the top for a CORRECT / NOT QUITE banner, colours
/// the options right/wrong, and drops in the explanation. A pixel header (its own back button, the
/// "DAILY QUIZ" bitmap title, and the hearts) sits above both. Presented full-screen over the tab bar.
struct QuizGameView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(FeedbackServices.self)
    private var feedback: FeedbackServices?

    @State private var game = QuizGameModel()

    var body: some View {
        Group {
            if game.phase == .finished {
                QuizCompleteView(game: game, onDone: { dismiss() })
            } else {
                playing
            }
        }
        .background(Color.egGround.ignoresSafeArea())
        .onAppear { game.feedback = feedback }
        .task {
            // One clock for the whole round; `tick()` only counts down while a question is open, so it's a
            // no-op on the reveal and summary and resumes cleanly after "Play again". Auto-cancels on close.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                game.tick()
            }
        }
    }

    // MARK: Playing (answering + revealing)

    private var playing: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: EgressSpacing.xl) {
                    if game.phase == .answering {
                        statRow

                        // Counter + progress read as one grouped pair, then the bubble sits apart.
                        VStack(alignment: .leading, spacing: EgressSpacing.sm) {
                            counterRow
                            QuizProgressBar(
                                total: game.total,
                                results: game.results,
                                currentIndex: game.index,
                                isAnswering: true
                            )
                        }

                        QuizMascotBubble(topic: game.current.topic, prompt: game.current.prompt)
                    } else {
                        QuizResultBanner(
                            correct: game.lastWasCorrect,
                            scoreDelta: lastDelta,
                            streak: game.streak
                        )
                    }

                    options

                    if game.phase == .revealed {
                        QuizExplanation(text: game.current.explanation)
                    }
                }
                .padding(.horizontal, EgressSpacing.lg)
                .padding(.top, EgressSpacing.sm)
                .padding(.bottom, EgressSpacing.xl)
                .animation(Motion.chip, value: game.phase)
                .animation(Motion.tap, value: game.selected)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) { cta }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            PixelText(text: "DAILY QUIZ", pixel: 3, color: .egTextPrimary)

            HStack {
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
                .accessibilityLabel("Close quiz")

                Spacer()

                hearts
            }
        }
        .padding(.horizontal, EgressSpacing.lg)
        .padding(.top, EgressSpacing.sm)
        .padding(.bottom, EgressSpacing.md)
    }

    private var hearts: some View {
        HStack(spacing: 5) {
            ForEach(0 ..< QuizGameModel.startingLives, id: \.self) { i in
                PixelHeart(filled: i < game.lives, size: 18)
            }
        }
        .animation(Motion.tap, value: game.lives)
        .accessibilityElement()
        .accessibilityLabel("\(game.lives) lives left")
    }

    // MARK: Stat row + counter (answering)

    private var statRow: some View {
        HStack(spacing: EgressSpacing.sm) {
            StatChip(systemImage: "flame.fill", text: "×\(game.streak)", tint: .egAccentTerracotta)
            StatChip(systemImage: "hourglass", text: "\(game.timeRemaining)", tint: .egAccentGold)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color.egAccentGold)
                Text("\(game.score)")
                    .font(.system(.headline, design: .monospaced, weight: .heavy))
                    .foregroundStyle(Color.egTextPrimary)
            }
            .accessibilityLabel("Score \(game.score)")
        }
    }

    private var counterRow: some View {
        HStack {
            Text("Question \(game.questionNumber)/\(game.total)")
                .egMicroLabel()
            Spacer()
            Text("+10 XP")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Color.egDataGreenDeep)
        }
    }

    // MARK: Options

    private var options: some View {
        VStack(spacing: EgressSpacing.sm) {
            ForEach(Array(game.current.options.enumerated()), id: \.offset) { i, option in
                Button {
                    game.select(i)
                } label: {
                    QuizOptionRow(letter: Self.letters[i], text: option, state: optionState(i))
                }
                .buttonStyle(RowPress())
                .disabled(game.phase != .answering)
                .accessibilityAddTraits(game.phase == .revealed && i == game.current.answer ? .isSelected : [])
            }
        }
    }

    private static let letters = ["A", "B", "C", "D"]

    private func optionState(_ i: Int) -> QuizOptionRow.Style {
        if game.phase == .answering {
            return game.selected == i ? .selected : .idle
        }
        if i == game.current.answer { return .correct }
        if i == game.selected { return .wrongPick }
        return .muted
    }

    /// Points earned on the just-answered question — mirrors the model's streak-bonus scoring.
    private var lastDelta: Int { 50 + max(0, game.streak - 1) * 10 }

    // MARK: Bottom CTA

    private var cta: some View {
        let answeringLocked = game.phase == .answering && !game.canCheck
        let showsArrow = game.phase == .revealed && !(game.isOutOfLives || game.isLastQuestion)

        return Button {
            switch game.phase {
            case .answering: game.check()
            case .revealed: game.advance()
            case .finished: break
            }
        } label: {
            HStack(spacing: EgressSpacing.sm) {
                Text(ctaTitle)
                    .font(EgressFont.body(.headline, weight: .heavy))
                if showsArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .heavy))
                }
            }
            .foregroundStyle(Color.egTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, EgressSpacing.lg)
            .background(GreenPill())
            .overlay(RoundedRectangle.egSquircle(EgressRadius.md).strokeBorder(Color.egOutline, lineWidth: 2))
        }
        .buttonStyle(RowPress())
        .disabled(answeringLocked)
        .opacity(answeringLocked ? 0.45 : 1)
        .animation(Motion.tap, value: answeringLocked)
        .padding(.horizontal, EgressSpacing.lg)
        .padding(.bottom, EgressSpacing.sm)
    }

    private var ctaTitle: String {
        switch game.phase {
        case .answering: "Check Answer"
        case .revealed: (game.isOutOfLives || game.isLastQuestion) ? "See Results" : "Next Question"
        case .finished: "Done"
        }
    }
}

// MARK: - StatChip

/// A bordered pixel chip in the answering stat row — an icon and a monospaced value (streak, timer).
private struct StatChip: View {
    let systemImage: String
    let text: String
    var tint: Color = .egTextSecondary

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(.footnote, design: .monospaced, weight: .heavy))
                .foregroundStyle(Color.egTextPrimary)
        }
        .padding(.horizontal, EgressSpacing.md)
        .padding(.vertical, 6)
        .background(PixelCornerRect(radius: 14, pixel: 3).fill(Color.egSurfaceRaised))
        .overlay(PixelCornerRect(radius: 14, pixel: 3).strokeBorder(Color.egOutline, lineWidth: 1.5))
    }
}

// MARK: - MiniPill

/// A small capsule badge inside the result banner (★ +50, 🔥 ×5, −1 life).
private struct MiniPill: View {
    let systemImage: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(.footnote, design: .monospaced, weight: .heavy))
                .foregroundStyle(Color.egTextPrimary)
        }
        .padding(.horizontal, EgressSpacing.sm)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.egSurfaceRaised))
        .overlay(Capsule().strokeBorder(Color.egOutline, lineWidth: 1.5))
    }
}

// MARK: - GreenPill

/// The app's chunky green button surface — a sage fill with a deep-green bottom lip and no border
/// (the outline is applied by the caller). Matches the "Play this scenario" button.
private struct GreenPill: View {
    var body: some View {
        RoundedRectangle.egSquircle(EgressRadius.md)
            .fill(Color.egDataGreen)
            .overlay(alignment: .bottom) {
                RoundedRectangle.egSquircle(EgressRadius.md)
                    .fill(Color.egDataGreenDeep)
                    .frame(height: 5)
                    .padding(.horizontal, 2)
            }
            .clipShape(RoundedRectangle.egSquircle(EgressRadius.md))
    }
}

// MARK: - QuizProgressBar

/// The ten-segment progress rail: answered questions read green (right) or terracotta (wrong), the
/// current one glows gold, and the rest sit sunken.
private struct QuizProgressBar: View {
    let total: Int
    let results: [Bool]
    let currentIndex: Int
    let isAnswering: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< total, id: \.self) { i in
                Capsule()
                    .fill(color(for: i))
                    .frame(height: 8)
                    .overlay(Capsule().strokeBorder(Color.egOutline.opacity(0.22), lineWidth: 1))
            }
        }
    }

    private func color(for i: Int) -> Color {
        if i < results.count { return results[i] ? .egDataGreen : .egAccentTerracotta }
        if i == currentIndex, isAnswering { return .egAccentGold }
        return .egSurfaceSunken
    }
}

// MARK: - QuizMascotBubble

/// RALLY beside a pixel-bordered speech bubble carrying the topic tag and the question.
private struct QuizMascotBubble: View {
    let topic: String
    let prompt: String

    var body: some View {
        HStack(alignment: .center, spacing: EgressSpacing.xs) {
            QuizRobot(width: 62)

            VStack(alignment: .leading, spacing: EgressSpacing.sm) {
                Text(topic).egMicroLabel()
                Text(prompt)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(Color.egTextPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, EgressSpacing.lg)
            .padding(.vertical, EgressSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PixelCornerRect(radius: EgressRadius.md, pixel: 4).fill(Color.egSurfaceRaised))
            .overlay(PixelCornerRect(radius: EgressRadius.md, pixel: 4).strokeBorder(Color.egOutline, lineWidth: 2))
            .overlay(alignment: .leading) {
                BubbleTail().offset(x: -10) // points back at the robot
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - QuizOptionRow

/// One answer option — a lettered chip, the option text, and a trailing marker. Its look is fully
/// determined by `Style`, so the same row renders the idle list, the live selection, and the reveal.
struct QuizOptionRow: View {
    /// idle / selected while answering; correct / wrongPick / muted after the reveal.
    enum Style { case idle, selected, correct, wrongPick, muted }

    let letter: String
    let text: String
    let state: Style

    var body: some View {
        HStack(spacing: EgressSpacing.md) {
            letterChip
            Text(text)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, EgressSpacing.md)
        .padding(.vertical, EgressSpacing.md)
        .background(PixelCornerRect(radius: EgressRadius.sm, pixel: 3).fill(fill))
        .overlay(PixelCornerRect(radius: EgressRadius.sm, pixel: 3).strokeBorder(border, lineWidth: borderWidth))
        .opacity(state == .muted ? 0.6 : 1)
        .contentShape(Rectangle())
        .animation(Motion.tap, value: state)
    }

    private var letterChip: some View {
        Text(letter)
            .font(.system(.subheadline, design: .rounded, weight: .heavy))
            .foregroundStyle(letterColor)
            .frame(width: 30, height: 30)
            .background(PixelCornerRect(radius: EgressRadius.xs, pixel: 2).fill(chipFill))
            .overlay(PixelCornerRect(radius: EgressRadius.xs, pixel: 2).strokeBorder(Color.egOutline.opacity(chipStroke), lineWidth: 1.5))
    }

    @ViewBuilder
    private var trailing: some View {
        switch state {
        case .idle:
            Circle().strokeBorder(Color.egOutline, lineWidth: 2).frame(width: 20, height: 20)
        case .selected:
            ZStack {
                Circle().fill(Color.egCyan)
                Circle().strokeBorder(Color.egOutline, lineWidth: 2)
            }
            .frame(width: 20, height: 20)
        case .correct:
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(Color.egTextPrimary)
        case .wrongPick:
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(Color.egSurfaceRaised)
        case .muted:
            Color.clear.frame(width: 20, height: 20)
        }
    }

    // MARK: Palette per state

    private var fill: Color {
        switch state {
        case .idle: .egSurfaceRaised
        case .selected: Color.egCyan.opacity(0.14)
        case .correct: .egDataGreen
        case .wrongPick: .egAccentTerracotta
        case .muted: .egSurfaceSunken
        }
    }

    private var border: Color {
        switch state {
        case .selected: .egCyan
        case .muted: .egSeparator
        default: .egOutline
        }
    }

    private var borderWidth: CGFloat { state == .selected ? 2.5 : 2 }

    private var textColor: Color {
        switch state {
        case .muted: .egTextTertiary
        case .wrongPick: .egSurfaceRaised
        default: .egTextPrimary
        }
    }

    private var chipFill: Color {
        switch state {
        case .selected: .egCyan
        case .correct, .wrongPick: .egCanvasBase
        default: .egSurfaceSunken
        }
    }

    private var chipStroke: Double { state == .muted ? 0.4 : 1 }

    private var letterColor: Color {
        switch state {
        case .selected, .correct, .wrongPick: .egSurfaceRaised
        case .muted: .egTextTertiary
        case .idle: .egTextPrimary
        }
    }
}

// MARK: - QuizResultBanner

/// The reveal banner that replaces the stat row: RALLY, the CORRECT! / NOT QUITE pixel title, and the
/// reward (or lost-life) badges.
private struct QuizResultBanner: View {
    let correct: Bool
    let scoreDelta: Int
    let streak: Int

    private var accent: Color { correct ? .egDataGreen : .egAccentGold }

    var body: some View {
        HStack(spacing: EgressSpacing.md) {
            QuizRobot(width: 50, accent: correct ? .egDataGreen : .egAccentTerracotta)
                .overlay(alignment: .top) { if correct { confetti } }

            VStack(alignment: .leading, spacing: EgressSpacing.sm) {
                PixelText(
                    text: correct ? "CORRECT!" : "NOT QUITE",
                    pixel: 4,
                    color: correct ? .egDataGreenDeep : .egAccentBrick
                )

                HStack(spacing: EgressSpacing.sm) {
                    if correct {
                        MiniPill(systemImage: "star.fill", text: "+\(scoreDelta)", tint: .egAccentGold)
                        MiniPill(systemImage: "flame.fill", text: "×\(streak)", tint: .egAccentTerracotta)
                    } else {
                        MiniPill(systemImage: "heart.slash.fill", text: "−1 life", tint: .egAccentBrick)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, EgressSpacing.xl)
        .padding(.vertical, EgressSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PixelCornerRect(radius: EgressRadius.md, pixel: 4).fill(accent.opacity(0.18)))
        .overlay(PixelCornerRect(radius: EgressRadius.md, pixel: 4).strokeBorder(accent, lineWidth: 2))
        .overlay(alignment: .topTrailing) { if correct { PixelPlus(color: .egAccentGold, unit: 4).padding(14) } }
        .overlay(alignment: .bottomTrailing) { if correct { PixelPlus(color: .egAccentGold, unit: 3).padding(.trailing, 20).padding(.bottom, 16) } }
        .accessibilityElement(children: .combine)
    }

    /// A small burst of coloured pixel flecks around the robot's head, celebrating a right answer.
    /// Anchored to the robot (via `.overlay(alignment: .top)`), so it tracks the robot at any padding.
    private var confetti: some View {
        ZStack {
            confettiDot(.egAccentTerracotta, -22, -6, 5)
            confettiDot(.egCyan, -2, -10, 5)
            confettiDot(.egAccentGold, 24, -2, 6)
            confettiDot(.egDataGreen, 26, 20, 5)
            confettiDot(.egAccentPlum, -26, 12, 4)
            confettiDot(.egDataGreenDeep, 8, -6, 4)
        }
        .allowsHitTesting(false)
    }

    private func confettiDot(_ color: Color, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: x, y: y)
    }
}

// MARK: - QuizExplanation

/// The one-line reason under the options after the reveal — a quiet card with a green rule.
private struct QuizExplanation: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: EgressSpacing.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.egDataGreen)
                .frame(width: 4)
            Text(text)
                .egBody(.subheadline)
                .foregroundStyle(Color.egTextSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(EgressSpacing.md)
        .background(RoundedRectangle.egSquircle(EgressRadius.sm).fill(Color.egSurfaceRaised))
        .overlay(RoundedRectangle.egSquircle(EgressRadius.sm).strokeBorder(Color.egSeparator, lineWidth: 1.5))
    }
}

// MARK: - QuizCompleteView

/// The end-of-round summary — RALLY, the final score, how many landed, and the two ways forward.
private struct QuizCompleteView: View {
    let game: QuizGameModel
    let onDone: () -> Void

    private var subtitle: String {
        if game.isOutOfLives { return "Out of lives — but every run teaches the geometry." }
        if game.ranOutOfTime { return "Time's up. Come back tomorrow for another." }
        return "You cleared the deck. Nicely read."
    }

    var body: some View {
        VStack(spacing: EgressSpacing.lg) {
            Spacer()

            QuizRobot(width: 90, accent: game.isOutOfLives ? .egAccentTerracotta : .egDataGreen)

            PixelText(text: "QUIZ DONE", pixel: 5, color: .egTextPrimary)

            Text(subtitle)
                .egBody(.subheadline)
                .foregroundStyle(Color.egTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: EgressSpacing.sm) {
                Image(systemName: "star.fill")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(Color.egAccentGold)
                PixelText(text: "\(game.score)", pixel: 6, color: .egAccentGold)
            }
            .padding(.top, EgressSpacing.sm)

            Text("\(game.correctCount) / \(game.total) correct")
                .font(.system(.headline, design: .monospaced, weight: .heavy))
                .foregroundStyle(Color.egTextPrimary)

            Spacer()

            VStack(spacing: EgressSpacing.md) {
                Button { game.restart() } label: {
                    Text("Play again")
                        .font(EgressFont.body(.headline, weight: .heavy))
                        .foregroundStyle(Color.egTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, EgressSpacing.lg)
                        .background(GreenPill())
                        .overlay(RoundedRectangle.egSquircle(EgressRadius.md).strokeBorder(Color.egOutline, lineWidth: 2))
                }
                .buttonStyle(RowPress())

                Button(action: onDone) {
                    Text("Done")
                        .font(EgressFont.body(.headline, weight: .heavy))
                        .foregroundStyle(Color.egTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, EgressSpacing.md)
                }
                .buttonStyle(RowPress())
            }
        }
        .padding(EgressSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.egGround)
    }
}

#Preview {
    QuizGameView()
        .environment(\.dependencies, .preview())
}
