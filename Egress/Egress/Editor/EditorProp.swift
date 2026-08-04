import EgressEngine
import SwiftUI

// MARK: - EditorProp

/// A single entry in the prop library the Props button opens. The library is a palette of named
/// furniture drawn from the six venue archetypes; picking one sets `EditorModel.activeProp` so the
/// next box the user drags out is tagged with that prop's identity and simulation class. The very
/// first entry, `.object`, is the plain freeform box the editor has always placed — the default, so
/// the Props tool keeps its current behaviour untouched.
struct EditorProp: Identifiable, Hashable {
    /// Stable identity, stored on the placed `Obstacle.kind`. "object" is the freeform default.
    let kind: String
    /// Display name shown on the chip, the tool pill, and the selection pad ("Bar", "Object").
    let name: String
    /// SF Symbol drawn on the library chip.
    let symbol: String
    /// The venue archetype this prop belongs to, or `nil` for the universal default box.
    let venue: String?
    /// Simulation class — carried onto the placed obstacle (blocking + relocatability).
    let simClass: ObstacleClass
    /// Suggested footprint in metres, shown as the chip's caption. Placement is still drag-to-size, so
    /// this is guidance, not a fixed stamp — the user draws the box exactly as they do today.
    let defaultSize: Vec2

    var id: String {
        kind
    }

    /// The short sim-class tag shown under the name ("move" / "struct" / "decor"), matching the design.
    var classLabel: String {
        switch simClass {
        case .relocatable: "move"
        case .structural: "struct"
        case .decor: "decor"
        }
    }

    /// The class's accent — green (relocatable, "coach may move"), cyan (structural anchor), muted taupe
    /// (decor, lowest contrast). Used for the chip's icon and its selected ring.
    var tint: Color {
        switch simClass {
        case .relocatable: .egDataGreen
        case .structural: .egCyan
        case .decor: .egTextTertiary
        }
    }
}

extension EditorProp {
    /// The freeform box the editor has always placed — the default active prop.
    static let object = EditorProp(
        kind: "object", name: "Object", symbol: "square.dashed",
        venue: nil, simClass: .relocatable, defaultSize: Vec2(1, 1)
    )

    /// The full palette shown in the sheet: the default box, then the six-archetype library from the
    /// design's PROP LIBRARY board (venue · sim-class preserved).
    static let library: [EditorProp] = [
        object,
        // Structural — fixed, routes plan around them.
        EditorProp(
            kind: "bar",
            name: "Bar",
            symbol: "wineglass",
            venue: "Nightclub",
            simClass: .structural,
            defaultSize: Vec2(3, 1)
        ),
        EditorProp(
            kind: "stage",
            name: "Stage",
            symbol: "music.mic",
            venue: "Concert Hall",
            simClass: .structural,
            defaultSize: Vec2(4, 2)
        ),
        EditorProp(
            kind: "turnstile",
            name: "Turnstile",
            symbol: "figure.walk",
            venue: "Metro Platform",
            simClass: .structural,
            defaultSize: Vec2(1, 0.5)
        ),
        EditorProp(
            kind: "lockers",
            name: "Lockers",
            symbol: "rectangle.split.3x1",
            venue: "School",
            simClass: .structural,
            defaultSize: Vec2(2, 0.5)
        ),
        EditorProp(
            kind: "pillar",
            name: "Pillar",
            symbol: "cylinder.fill",
            venue: "Metro Platform",
            simClass: .structural,
            defaultSize: Vec2(0.5, 0.5)
        ),
        EditorProp(
            kind: "seating",
            name: "Seating",
            symbol: "chair.fill",
            venue: "Concert Hall",
            simClass: .structural,
            defaultSize: Vec2(3, 1)
        ),
        // Relocatable — furniture the coach may suggest moving.
        EditorProp(
            kind: "hitable",
            name: "Hi-Table",
            symbol: "table.furniture",
            venue: "Nightclub",
            simClass: .relocatable,
            defaultSize: Vec2(0.75, 0.75)
        ),
        EditorProp(
            kind: "speaker",
            name: "Speaker",
            symbol: "hifispeaker.fill",
            venue: "Nightclub",
            simClass: .relocatable,
            defaultSize: Vec2(0.5, 0.5)
        ),
        EditorProp(
            kind: "desk",
            name: "Desk",
            symbol: "studentdesk",
            venue: "Office",
            simClass: .relocatable,
            defaultSize: Vec2(1.5, 0.75)
        ),
        EditorProp(
            kind: "bench",
            name: "Bench",
            symbol: "chair.lounge.fill",
            venue: "Metro Platform",
            simClass: .relocatable,
            defaultSize: Vec2(2, 0.5)
        ),
        EditorProp(
            kind: "equiprack",
            name: "Equip Rack",
            symbol: "dumbbell.fill",
            venue: "Gym",
            simClass: .relocatable,
            defaultSize: Vec2(1.5, 0.75)
        ),
        // Decor — sim-inert, never blocks a body.
        EditorProp(
            kind: "planter",
            name: "Planter",
            symbol: "leaf.fill",
            venue: "Office",
            simClass: .decor,
            defaultSize: Vec2(0.75, 0.75)
        )
    ]

    /// Every prop keyed by its stored `kind`, for resolving a placed obstacle back to its identity.
    static let byKind: [String: EditorProp] = Dictionary(
        uniqueKeysWithValues: library.map { ($0.kind, $0) }
    )

    /// The display name for a stored `kind` (falls back to the default box for unknown/legacy props).
    static func name(forKind kind: String) -> String {
        byKind[kind]?.name ?? object.name
    }
}
