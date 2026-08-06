import Foundation

/// A furnished starter venue for the Spaces gallery. Pure data: a fully-authored `VenueModel`
/// (walls, exits, props) plus a default crowd, so tapping a card drops the user into a *real*
/// simulable room rather than an empty rectangle (§2.13.3 — "no empty boxes"). Prop layouts leave
/// the primary egress routes clear, so the run reflects a genuine flaw (or a genuine pass), never a
/// rigged one. The metre coordinates here match the editor's 0.25 m grid exactly.
public struct VenuePreset: Identifiable, Sendable {
    public let id: String
    /// Short venue name — also becomes the editor's pre-filled name and the run record's title.
    public let title: String
    /// One-line pitch shown under the title on the gallery card.
    public let blurb: String
    /// The furnished venue the editor loads and the engine runs.
    public let venue: VenueModel
    /// Default occupancy — becomes `SimulationConfig.agentCount`. Chosen to make each layout's
    /// character read on the first run (comfortable clear-out vs. a doorway that jams).
    public let crowd: Int
    /// Pre-placed fire ignition points in world metres — fed into the editor and, from there, into
    /// `SimulationConfig.ignition`. Empty for most presets; The Vault seeds the money-shot fire here so
    /// its dramatic FAIL survives the Spaces → editor → Run path (there is no more Simulate demo tab).
    public let ignitions: [Vec2]

    public init(id: String, title: String, blurb: String, venue: VenueModel, crowd: Int, ignitions: [Vec2] = []) {
        self.id = id
        self.title = title
        self.blurb = blurb
        self.venue = venue
        self.crowd = crowd
        self.ignitions = ignitions
    }

    /// Room extent in metres — for the card subtitle and for seeding the editor's steppers.
    public var widthMetres: Double { venue.geometry.worldWidth }
    public var heightMetres: Double { venue.geometry.worldHeight }

    /// The furnished catalog shown in Spaces, ordered easy → hard: the first card reads as a
    /// friendly starting point, the demo's failing layout (The Vault) sits second for the money shot.
    public static let catalog: [VenuePreset] = [office, nightclub, concertHall, transitHub, classroom]
}

// MARK: - Authoring helpers

/// Grid for a room of the given metre extent, on the standard 0.25 m cells — identical to the
/// conversion `EditorModel.geometry` uses, so a preset round-trips through the editor unchanged.
private func presetGeometry(_ widthM: Double, _ heightM: Double) -> GridGeometry {
    let cs = SafetyStandards.cellSize
    return GridGeometry(size: GridSize(
        width: Int((widthM / cs).rounded()),
        height: Int((heightM / cs).rounded())
    ))
}

/// A movable prop (desk, table, bench, kiosk) — the coach may propose relocating these.
private func prop(_ id: Int, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Obstacle {
    Obstacle(id: id, origin: Vec2(x, y), size: Vec2(w, h), isRelocatable: true)
}

/// A structural prop (stage, bar, seating block, column) — never relocatable; the coach routes
/// around it instead of moving it (§2.13.3, validation V5).
private func structural(_ id: Int, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Obstacle {
    Obstacle(id: id, origin: Vec2(x, y), size: Vec2(w, h), isRelocatable: false)
}

// MARK: - The catalog

extension VenuePreset {
    /// Office — open-plan desks, two wide doors, a light crowd. The comfortable PASS baseline
    /// (§2.13.3 lists offices as fully relocatable — no structural props).
    static let office = VenuePreset(
        id: "office",
        title: "Startup Floor",
        blurb: "Open-plan desks and two wide doors — a comfortable clear-out.",
        venue: VenueModel(
            id: 0, name: "Startup Floor", type: .office,
            geometry: presetGeometry(16, 12),
            exits: [
                Exit(id: 1, a: Vec2(7.2, 12), b: Vec2(8.8, 12)),  // 1.6 m main door, bottom-centre
                Exit(id: 2, a: Vec2(16, 2.0), b: Vec2(16, 3.2))   // 1.2 m side door, right wall
            ],
            obstacles: [
                prop(10, 2, 2, 3, 1.2), prop(11, 2, 4.8, 3, 1.2), prop(12, 2, 7.6, 3, 1.2), // left desk pods
                prop(13, 11, 2, 3, 1.2), prop(14, 11, 4.8, 3, 1.2),                          // right desk pods
                prop(15, 11, 8, 3, 2.5),   // meeting pod
                prop(16, 7.5, 2, 1, 1.5),  // printer bank
                prop(17, 6.5, 9.8, 3, 1)   // lockers
            ]
        ),
        crowd: 55
    )

    /// Nightclub — one tight door, a bar and stage boxing in a packed floor. The demo's *failing*
    /// layout: the crowd overruns the single 1.0 m exit and jams the doorway (R-09 money shot).
    static let nightclub = VenuePreset(
        id: "nightclub",
        title: "The Vault",
        blurb: "One tight door, a packed floor — watch the exit jam.",
        venue: VenueModel(
            id: 0, name: "The Vault", type: .nightclub,
            geometry: presetGeometry(11, 8),
            exits: [
                Exit(id: 1, a: Vec2(5, 8), b: Vec2(6, 8))  // 1.0 m door, bottom-centre
            ],
            obstacles: [
                structural(10, 1, 0, 6, 1.3),      // bar run, flush to the top wall (no strip behind it)
                structural(11, 8, 0, 3, 2.5),      // stage block, filling the top-right corner
                structural(12, 0.5, 6, 0.7, 1),    // speaker stack
                prop(13, 2, 3.5, 1, 1), prop(14, 4.5, 4.5, 1, 1),
                prop(15, 7, 3.5, 1, 1), prop(16, 8.5, 5.2, 1, 1)  // standing tables
            ]
        ),
        crowd: 150,
        ignitions: [Vec2(5.5, 6.0)] // fire seeded in the exit queue — the money-shot FAIL (was SampleVenue.moneyShotIgnition)
    )

    /// Concert Hall — a stage, two seating blocks, and crowd barriers funnelling to a wide main
    /// exit, plus a narrow side door. Big crowd through a barriered throat.
    static let concertHall = VenuePreset(
        id: "concertHall",
        title: "Amphitheatre",
        blurb: "Seating blocks funnel a big crowd to a barriered main exit.",
        venue: VenueModel(
            id: 0, name: "Amphitheatre", type: .concertHall,
            geometry: presetGeometry(20, 14),
            walls: [
                Wall(a: Vec2(8.5, 12), b: Vec2(8.5, 14)),   // crowd barriers narrowing the main exit
                Wall(a: Vec2(11.5, 12), b: Vec2(11.5, 14))
            ],
            exits: [
                Exit(id: 1, a: Vec2(9, 14), b: Vec2(11, 14)),  // 2.0 m main exit, bottom-centre
                Exit(id: 2, a: Vec2(0, 6), b: Vec2(0, 7.2))    // 1.2 m side exit, left wall
            ],
            obstacles: [
                structural(10, 4, 0.5, 12, 2.5),  // stage
                structural(11, 2, 5, 7, 6),       // seating block, house left
                structural(12, 11, 5, 7, 6),      // seating block, house right
                prop(13, 16.5, 11.5, 1.5, 1.5)    // merch stand
            ]
        ),
        crowd: 180
    )

    /// Transit Hub — a long platform draining to stairs at both ends, with a row of structural
    /// columns down the middle, a turnstile bank, benches and a kiosk.
    static let transitHub = VenuePreset(
        id: "transitHub",
        title: "Platform 2",
        blurb: "A long platform draining to stairs at both ends, past the columns.",
        venue: VenueModel(
            id: 0, name: "Platform 2", type: .transitHub,
            geometry: presetGeometry(24, 8),
            exits: [
                Exit(id: 1, a: Vec2(0, 3), b: Vec2(0, 4.5)),    // 1.5 m stair, left end
                Exit(id: 2, a: Vec2(24, 3), b: Vec2(24, 4.5))   // 1.5 m stair, right end
            ],
            obstacles: [
                structural(10, 4, 3.6, 0.6, 0.8), structural(11, 8, 3.6, 0.6, 0.8),
                structural(12, 12, 3.6, 0.6, 0.8), structural(13, 16, 3.6, 0.6, 0.8),
                structural(14, 20, 3.6, 0.6, 0.8),   // columns down the platform centreline
                structural(15, 11, 0.5, 2, 1),       // turnstile bank
                prop(16, 3, 6.4, 2, 0.8), prop(17, 9, 6.4, 2, 0.8),
                prop(18, 15, 6.4, 2, 0.8), prop(19, 20, 6.4, 2, 0.8),  // benches
                prop(20, 11, 6, 1.5, 1.4)            // kiosk
            ]
        ),
        crowd: 150
    )

    /// Classroom — desk rows either side of a centre aisle, lab benches along the back wall, one
    /// door, a small calm crowd. A clean PASS — the orderly school-drill layout.
    static let classroom = VenuePreset(
        id: "classroom",
        title: "Lecture Room 3",
        blurb: "Desk rows and one door — a calm, orderly school drill.",
        venue: VenueModel(
            id: 0, name: "Lecture Room 3", type: .classroom,
            geometry: presetGeometry(10, 8),
            exits: [
                Exit(id: 1, a: Vec2(1.5, 8), b: Vec2(2.7, 8))  // 1.2 m door, bottom-left
            ],
            obstacles: [
                structural(10, 1, 0.5, 8, 0.8),  // lab benches, back wall
                prop(11, 1, 2, 3, 0.8), prop(12, 1, 3.6, 3, 0.8), prop(13, 1, 5.2, 3, 0.8),  // left desk rows
                prop(14, 6, 2, 3, 0.8), prop(15, 6, 3.6, 3, 0.8), prop(16, 6, 5.2, 3, 0.8),  // right desk rows
                prop(17, 4, 6.4, 2, 1)  // lockers
            ]
        ),
        crowd: 30
    )
}
