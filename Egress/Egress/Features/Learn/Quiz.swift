import Foundation

// MARK: - QuizQuestion

/// One multiple-choice question in the Daily Quiz (design: the quiz screenshot). Pure data — the topic
/// tag shown in RALLY's speech bubble, the prompt, the answer options, the index of the correct one, and
/// the one-line explanation revealed after answering.
///
/// All content is original and *principle-based* — how crowd flow and egress actually behave — framed as
/// general rules of thumb rather than citations of any specific building code, so the quiz teaches the
/// intuition the simulator is built to show, not a legal figure.
struct QuizQuestion: Identifiable, Hashable {
    let id = UUID()
    /// The short uppercase tag over the prompt ("CORRIDORS").
    let topic: String
    let prompt: String
    /// Two-to-four answer options, shown A/B/C/D in order.
    let options: [String]
    /// Index into `options` of the correct answer.
    let answer: Int
    /// The one-line reason revealed after the player checks their answer.
    let explanation: String
}

extension LearnLibrary {
    /// The Daily Quiz deck — ten questions on the ideas the simulator makes visible: flow capacity,
    /// bottlenecks, exit redundancy and density. Static, so a session always sees the same deck.
    static let quiz: [QuizQuestion] = [
        QuizQuestion(
            topic: "Corridors",
            prompt: "What clear width does an assembly corridor need?",
            options: ["0.7 m", "0.9 m", "1.2 m", "2.0 m"],
            answer: 2,
            explanation: "1.2 m lets two lanes of people pass without the flow collapsing — the assembly-corridor minimum in most codes."
        ),
        QuizQuestion(
            topic: "Exits",
            prompt: "When you size exits, what should the plan assume about them?",
            options: [
                "Every exit stays usable",
                "The largest exit is unavailable",
                "Half the crowd has already left",
                "People leave the way they came in",
            ],
            answer: 1,
            explanation: "Capacity is checked with the single largest exit discounted, so one blocked door never leaves the space under-served."
        ),
        QuizQuestion(
            topic: "Flow",
            prompt: "What mainly governs how fast a crowd surge clears?",
            options: [
                "How calm people stay",
                "The flow capacity of the exit route",
                "The lighting level",
                "The colour of the signage",
            ],
            answer: 1,
            explanation: "Outflow is limited by the narrowest point on the route; when arrivals outrun it, density climbs no matter how people behave."
        ),
        QuizQuestion(
            topic: "Density",
            prompt: "Around what crowd density does movement become difficult and risky?",
            options: ["1 person / m²", "2 people / m²", "4 people / m²", "8 people / m²"],
            answer: 2,
            explanation: "Near 4 people per m² individual movement is lost and pressure builds; comfortable flow sits well below that."
        ),
        QuizQuestion(
            topic: "Doors",
            prompt: "Why do exit doors swing outward, in the direction of travel?",
            options: [
                "It looks tidier",
                "A pressing crowd can't hold them shut",
                "They cost less to fit",
                "It saves floor space",
            ],
            answer: 1,
            explanation: "A door that opens the way people are moving can't be jammed closed by the weight of the crowd behind it."
        ),
        QuizQuestion(
            topic: "Travel distance",
            prompt: "What does the \u{201C}travel distance\u{201D} limit measure?",
            options: [
                "How far the car park is",
                "The furthest anyone is from an exit",
                "The height of the corridor",
                "The width of the stairs",
            ],
            answer: 1,
            explanation: "Codes cap how far anyone must travel to reach a protected exit, so no one is ever far from a way out."
        ),
        QuizQuestion(
            topic: "Signage",
            prompt: "Where should exit signage be visible?",
            options: [
                "Only at the main door",
                "Along the whole route, including low down",
                "Just at ceiling height",
                "Only when the lights fail",
            ],
            answer: 1,
            explanation: "Continuous, low-mounted signs stay readable through smoke and guide people the entire way out."
        ),
        QuizQuestion(
            topic: "Bottleneck",
            prompt: "Two wide corridors feed into one narrow door. What happens?",
            options: [
                "Outflow roughly doubles",
                "A queue forms at the door",
                "Nothing changes",
                "Everyone speeds up",
            ],
            answer: 1,
            explanation: "Outflow is set by the narrowest point; merging two flows into one undersized door forms a queue and raises density."
        ),
        QuizQuestion(
            topic: "Alarms",
            prompt: "What is an evacuation alarm mainly for?",
            options: [
                "Starting the sprinklers",
                "Getting people moving early",
                "Calling the lift",
                "Locking the doors",
            ],
            answer: 1,
            explanation: "Early warning buys evacuation time — the sooner people start moving, the more the exits can clear before conditions worsen."
        ),
        QuizQuestion(
            topic: "Stairs",
            prompt: "How are protected stairwells kept usable in a tall building?",
            options: [
                "Held open to every floor",
                "Kept smoke-free, often pressurised",
                "Used for extra storage",
                "Made narrower than the corridors",
            ],
            answer: 1,
            explanation: "Keeping stairs smoke-free preserves the one vertical escape route for everyone on the floors above."
        ),
    ]
}
