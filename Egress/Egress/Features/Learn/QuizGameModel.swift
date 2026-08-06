import SwiftUI

// MARK: - QuizGameModel

/// The Daily Quiz game state (design: the quiz screenshot). A small, self-contained round: the deck is
/// fixed, state lives in memory, and every fresh presentation starts a new game — nothing is persisted.
///
/// The loop is answer → check → reveal → next. Answering a question correctly grows the **streak** and the
/// **score** (with a streak bonus); a wrong answer — or letting the **timer** run out — breaks the streak
/// and costs a **life**. Running out of lives, or reaching the last card, ends the round on the summary.
@MainActor
@Observable
final class QuizGameModel {
    enum Phase {
        case answering // choosing an option; the timer is running
        case revealed // the answer is shown, right or wrong; the timer is paused
        case finished // the round is over — summary screen
    }

    /// Seconds on the clock for the whole round.
    static let startingTime = 120
    /// Lives (hearts) the player starts with.
    static let startingLives = 3

    let questions: [QuizQuestion]

    private(set) var index = 0
    private(set) var selected: Int?
    private(set) var phase: Phase = .answering
    private(set) var lives = startingLives
    private(set) var streak = 0
    private(set) var score = 0
    private(set) var correctCount = 0
    private(set) var timeRemaining = startingTime
    /// Outcome of each question already answered, in order — drives the progress bar.
    private(set) var results: [Bool] = []

    /// Injected by the view on appear (a `@State` model can't read the environment at init).
    var feedback: FeedbackServices?

    init(questions: [QuizQuestion] = LearnLibrary.quiz) {
        self.questions = questions
    }

    // MARK: Derived

    var current: QuizQuestion { questions[min(index, questions.count - 1)] }
    var total: Int { questions.count }
    var questionNumber: Int { index + 1 }
    var isLastQuestion: Bool { index >= questions.count - 1 }
    var isOutOfLives: Bool { lives <= 0 }
    /// Whether the just-answered question was right (drives the reveal banner). Time-outs read as wrong.
    var lastWasCorrect: Bool { results.last ?? false }
    /// Whether the timer has run out — lets the summary explain the ending.
    var ranOutOfTime: Bool { timeRemaining <= 0 }
    var canCheck: Bool { phase == .answering && selected != nil }

    // MARK: Actions

    /// Pick an option while answering (re-selectable until the player checks).
    func select(_ option: Int) {
        guard phase == .answering else { return }
        selected = option
        feedback?.haptics.play(.toolTap)
    }

    /// Lock in the current selection and reveal the result.
    func check() {
        guard phase == .answering, let selected else { return }
        resolve(correct: selected == current.answer)
    }

    /// Advance from the reveal to the next card — or to the summary if the round is over.
    func advance() {
        guard phase == .revealed else { return }
        if isOutOfLives || isLastQuestion {
            phase = .finished
            feedback?.haptics.play(isOutOfLives ? .verdictFail : .verdictPass)
            return
        }
        index += 1
        selected = nil
        phase = .answering
    }

    /// One clock tick, driven by the view's timer. Only runs down while a question is open.
    func tick() {
        guard phase == .answering, timeRemaining > 0 else { return }
        timeRemaining -= 1
        if timeRemaining == 0 { resolve(correct: false) } // time's up — scored as a miss
    }

    /// Start a brand-new round (from the summary's "Play again").
    func restart() {
        index = 0
        selected = nil
        phase = .answering
        lives = Self.startingLives
        streak = 0
        score = 0
        correctCount = 0
        timeRemaining = Self.startingTime
        results = []
    }

    // MARK: Scoring

    /// Score the current question and move to the reveal, updating streak, lives and the running total.
    private func resolve(correct: Bool) {
        results.append(correct)
        if correct {
            correctCount += 1
            streak += 1
            score += 50 + max(0, streak - 1) * 10 // base 50, +10 per question of the running streak
            feedback?.haptics.play(.verdictPass)
        } else {
            streak = 0
            lives = max(0, lives - 1)
            feedback?.haptics.play(.verdictWarn)
        }
        phase = .revealed
    }
}
