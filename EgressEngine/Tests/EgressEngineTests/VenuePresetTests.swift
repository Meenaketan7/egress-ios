@testable import EgressEngine
import Testing

/// Guards the furnished starter catalog. These are the venues a first-time user taps into, so a
/// preset that can't drain — a prop layout that seals a pocket, an exit walled off by a barrier —
/// must fail here, long before it reaches the simulator. The drain check reuses the engine's own
/// exit seeding + flood, so it agrees exactly with what a real run (and `EditorModel.isSimulable`)
/// would see.
@Suite("Venue presets")
struct VenuePresetTests {
    /// Fraction of free floor that can reach an exit — the same computation `EditorModel` gates on.
    private func reachableFraction(_ venue: VenueModel) -> Double {
        let size = venue.geometry.size
        let blocked = BlockedCells.of(venue)
        let seeds = Simulation.exitCells(venue.exits, in: venue.geometry)
        let field = FlowField(size: size, blocked: blocked, exits: seeds)
        var free = 0, reachable = 0
        for index in 0 ..< size.count {
            let coord = size.coord(atIndex: index)
            if blocked.contains(coord) { continue }
            free += 1
            if field.isReachable(coord) { reachable += 1 }
        }
        return free > 0 ? Double(reachable) / Double(free) : 0
    }

    @Test("Catalog is non-empty and every id is unique")
    func catalogShape() {
        let catalog = VenuePreset.catalog
        #expect(!catalog.isEmpty)
        #expect(Set(catalog.map(\.id)).count == catalog.count)
    }

    @Test("Every preset is a valid, furnished, drainable room", arguments: VenuePreset.catalog)
    func presetIsSimulable(_ preset: VenuePreset) {
        let venue = preset.venue
        // A real grid with at least one exit.
        #expect(venue.isValid, "\(preset.id) must be a valid venue")
        // Furnished — the §2.13.3 "no empty boxes" rule.
        #expect(!venue.obstacles.isEmpty, "\(preset.id) must ship with props")
        // Crowd within the validated budget the editor's config allows.
        #expect(preset.crowd >= EgressEngine_minPresetCrowd && preset.crowd <= 300)
        // Element ids don't collide (the editor advances nextID past these).
        let ids = venue.exits.map(\.id) + venue.obstacles.map(\.id)
        #expect(Set(ids).count == ids.count, "\(preset.id) has colliding element ids")
        // Most of the floor must actually reach an exit — the run's own view of the layout.
        #expect(reachableFraction(venue) >= 0.5, "\(preset.id) floor does not drain")
    }

    @Test("Every element sits inside its room")
    func elementsInBounds() {
        for preset in VenuePreset.catalog {
            let w = preset.widthMetres, h = preset.heightMetres
            for o in preset.venue.obstacles {
                #expect(o.origin.x >= 0 && o.origin.y >= 0, "\(preset.id) prop \(o.id) off-canvas")
                #expect(o.origin.x + o.size.x <= w + 1e-9, "\(preset.id) prop \(o.id) overflows width")
                #expect(o.origin.y + o.size.y <= h + 1e-9, "\(preset.id) prop \(o.id) overflows height")
            }
        }
    }
}

/// Lower bound the catalog test checks crowds against — kept above `EditorModel.minCrowd` (5) so a
/// preset is always a meaningfully-loaded room.
let EgressEngine_minPresetCrowd = 10
