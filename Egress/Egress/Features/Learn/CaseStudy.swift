import EgressEngine
import SwiftUI

// MARK: - CaseStudy

/// One case study in the Learn tab. Either a **fictional** scenario the reader can actually play — it maps
/// to a simulable `VenuePreset`, so "Play this scenario" drops them into the editor/sim — or a **real
/// incident** recreation presented for education only, without blame or casualty imagery (design: the two
/// case-study detail screens). Pure data. Hashable by `id` so it can drive a `navigationDestination`
/// (`VenuePreset` itself isn't Hashable, hence the hand-written conformance).
struct CaseStudy: Identifiable, Hashable {
    enum Kind {
        case fictional // playable — has a `preset` to run
        case realIncident // read-only recreation, no play button

        /// The eyebrow tag above the detail header (uppercased at the view).
        var eyebrow: String {
            switch self {
            case .fictional: "Case study · Fictional"
            case .realIncident: "Case study · Real incident"
            }
        }
    }

    let id: String
    /// Title as it reads in the list row ("Station Platform, 2001").
    let rowTitle: String
    /// Title as it reads on the detail screen ("Station Platform Crowd Surge").
    let detailTitle: String
    /// The status line under the row title ("Fictional · playable").
    let rowSubtitle: String
    let kind: Kind
    /// Real-incident only — the small line under the detail title, above the rule.
    let attribution: String?
    /// Body paragraphs, in order.
    let paragraphs: [String]
    /// Real-incident only — the sourcing note in the quiet footer.
    let sourceNote: String?
    /// Difficulty shown on the playable thumbnail's badge, 1…3 (two dots lit for the Atrium).
    let difficulty: Int
    /// The simulable venue behind "Play this scenario" — nil for real incidents.
    let preset: VenuePreset?

    static func == (lhs: CaseStudy, rhs: CaseStudy) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Learn library

/// The Learn tab's authored content — the daily quiz prompt, the tips shelf entry, and the case studies.
/// Kept apart from the views so the copy reads in one place and stays easy to edit.
enum LearnLibrary {
    static let dailyQuiz = QuizPrompt(question: "What clear width does an assembly corridor need?")

    static let caseStudies: [CaseStudy] = [atrium, stationPlatform]

    /// The Atrium, authored to the case study's own numbers so the simulation matches the brief exactly:
    /// a 20 × 14 m assembly floor for **600 visitors**, with **four exits** — but two of them open only
    /// through a single **1.0 m vestibule pinch** (a walled pocket, bottom-right), the undersized bottleneck
    /// the study is about — and a **service-corridor fire** seeded near the central core to trip the alarm.
    private static let atriumPreset: VenuePreset = {
        let cell = 0.25
        func cells(_ m: Double) -> Int { Int((m / cell).rounded()) }
        // Structural props (stairs, desk, stage) are never relocatable; furniture is.
        func structural(_ id: Int, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Obstacle {
            Obstacle(id: id, origin: Vec2(x, y), size: Vec2(w, h), isRelocatable: false)
        }
        func furniture(_ id: Int, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Obstacle {
            Obstacle(id: id, origin: Vec2(x, y), size: Vec2(w, h), isRelocatable: true)
        }

        let venue = VenueModel(
            id: 0,
            name: "The Crowded Atrium",
            type: .concertHall,
            geometry: GridGeometry(size: GridSize(width: cells(20), height: cells(14))),
            walls: [
                // The vestibule pocket, bottom-right: reachable only through a single 1.0 m gap in its top
                // wall — the "undersized vestibule" that throttles the two exits inside it.
                Wall(a: Vec2(14, 10.5), b: Vec2(16.5, 10.5)), // top wall, left of the 1.0 m entrance
                Wall(a: Vec2(17.5, 10.5), b: Vec2(20, 10.5)), // top wall, right of the entrance
                Wall(a: Vec2(14, 10.5), b: Vec2(14, 14))      // inner-left wall closing the pocket
            ],
            exits: [
                Exit(id: 1, a: Vec2(15, 14), b: Vec2(16.2, 14)),  // vestibule exit A (1.2 m)
                Exit(id: 2, a: Vec2(17.8, 14), b: Vec2(19, 14)),  // vestibule exit B (1.2 m)
                Exit(id: 3, a: Vec2(0, 5), b: Vec2(0, 6.5)),      // west exit (1.5 m), independent
                Exit(id: 4, a: Vec2(8, 0), b: Vec2(9.5, 0))       // north exit (1.5 m), independent
            ],
            obstacles: [
                structural(10, 8.5, 6, 3, 2.5),   // central escalator / stair core (three-storey circulation)
                structural(11, 2, 1.5, 4.5, 1.2), // reception desk, top-left
                structural(12, 12, 1.5, 5, 2),    // launch stage / podium, top-right
                furniture(13, 2.5, 10.5, 3, 1.4), // seating cluster
                furniture(14, 9.5, 10.5, 1.4, 1.4), // info kiosk
                furniture(15, 5.5, 8.5, 1, 1),    // planter
                furniture(16, 11.5, 9, 1, 1),     // planter
                furniture(17, 6, 4.5, 1.6, 1)     // merch table
            ]
        )

        return VenuePreset(
            id: "atrium",
            title: "The Crowded Atrium",
            blurb: "A three-storey atrium at launch capacity, draining through one undersized vestibule.",
            venue: venue,
            crowd: 600,
            ignitions: [Vec2(9, 9.5)] // service-corridor fire by the central core — trips the alarm
        )
    }()

    /// Fictional & playable — a bottleneck scenario. Backed by the relabelled Atrium preset above.
    static let atrium = CaseStudy(
        id: "atrium",
        rowTitle: "The Crowded Atrium",
        detailTitle: "The Crowded Atrium",
        rowSubtitle: "Fictional · playable",
        kind: .fictional,
        attribution: nil,
        paragraphs: [
            "A three-storey atrium hosts a launch. Six hundred visitors gather when a service-corridor fire triggers the alarm.",
            "Two of four exits feed one undersized vestibule. The question is whether the geometry lets people out."
        ],
        sourceNote: nil,
        difficulty: 2,
        preset: atriumPreset
    )

    /// A real-incident recreation — read-only, framed carefully for education (no play button).
    static let stationPlatform = CaseStudy(
        id: "station-platform",
        rowTitle: "Station Platform, 2001",
        detailTitle: "Station Platform Crowd Surge",
        rowSubtitle: "Real incident · sourced",
        kind: .realIncident,
        attribution: "Recreation · approximate · educational",
        paragraphs: [
            "On a crowded evening, arriving passengers met a platform already at capacity. A narrowing near the single stairwell reduced outward flow below the rate people entered.",
            "Density rose faster than the platform could clear. Investigators attributed the outcome to the geometry of the exit route, not the behaviour of those present.",
            "This recreation illustrates how flow capacity, not panic, governs a surge."
        ],
        sourceNote: "Sourced from public inquiry summaries · presented for education, without blame or casualty imagery.",
        difficulty: 2,
        preset: nil
    )
}

/// The daily-quiz prompt shown on the Learn home card.
struct QuizPrompt {
    let question: String
}
