import Testing
@testable import EgressEngine

@Suite("Venue")
struct VenueTests {

    @Test("Exit width and centre")
    func exit() {
        let e = Exit(id: 1, a: Vec2(0, 0), b: Vec2(0, 2))
        #expect(e.width == 2)
        #expect(e.center == Vec2(0, 1))
    }

    @Test("Wall length")
    func wall() {
        #expect(Wall(a: Vec2(0, 0), b: Vec2(3, 4)).length == 5)
    }

    @Test("Obstacle area and containment (half-open box)")
    func obstacle() {
        let o = Obstacle(id: 1, origin: Vec2(2, 2), size: Vec2(1, 3), isRelocatable: true)
        #expect(o.area == 3)
        #expect(o.contains(Vec2(2.5, 4)))    // inside
        #expect(!o.contains(Vec2(2.5, 5)))   // on the far edge → excluded
        #expect(!o.contains(Vec2(1.9, 3)))   // left of origin
    }

    @Test("Every venue type has a non-empty display name")
    func venueTypes() {
        #expect(VenueType.allCases.count >= 3)
        for t in VenueType.allCases { #expect(!t.displayName.isEmpty) }
    }

    @Test("Gross and net floor area")
    func floorArea() {
        let v = VenueModel(
            id: 1, name: "Test", type: .office,
            geometry: GridGeometry(size: GridSize(width: 40, height: 40)),
            exits: [Exit(id: 1, a: Vec2(0, 0), b: Vec2(0, 1))],
            obstacles: [Obstacle(id: 1, origin: Vec2(1, 1), size: Vec2(2, 2), isRelocatable: false)]
        )
        #expect(v.grossFloorArea == 100)   // 10 m × 10 m
        #expect(v.netFloorArea == 96)      // minus the 4 m² obstacle
    }

    @Test("A venue needs an exit to be valid")
    func validity() {
        let geo = GridGeometry(size: GridSize(width: 40, height: 40))
        let noExit   = VenueModel(id: 1, name: "X", type: .office, geometry: geo)
        let withExit = VenueModel(id: 2, name: "Y", type: .office, geometry: geo,
                                  exits: [Exit(id: 1, a: Vec2(0, 0), b: Vec2(0, 1))])
        #expect(!noExit.isValid)
        #expect(withExit.isValid)
    }

    @Test("A venue is a pure value — rebuilding it yields an equal model")
    func equality() {
        let geo = GridGeometry(size: GridSize(width: 20, height: 20))
        func build() -> VenueModel {
            VenueModel(id: 7, name: "Same", type: .nightclub, geometry: geo,
                       exits: [Exit(id: 1, a: Vec2(0, 0), b: Vec2(0, 2))])
        }
        #expect(build() == build())
    }
}
