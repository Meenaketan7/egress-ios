/// A complete, editable venue: geometry plus its elements.
/// A pure value — the editor produces new instances; the simulation reads them.
public struct VenueModel: Identifiable, Equatable, Sendable {
    public let id: Int
    public var name: String
    public var type: VenueType
    public var geometry: GridGeometry
    public var walls: [Wall]
    public var exits: [Exit]
    public var obstacles: [Obstacle]
    public var decor: [DecorTile]

    public init(
        id: Int,
        name: String,
        type: VenueType,
        geometry: GridGeometry,
        walls: [Wall] = [],
        exits: [Exit] = [],
        obstacles: [Obstacle] = [],
        decor: [DecorTile] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.geometry = geometry
        self.walls = walls
        self.exits = exits
        self.obstacles = obstacles
        self.decor = decor
    }

    /// Gross floor area, in m² (before subtracting obstacles).
    public var grossFloorArea: Double {
        geometry.worldWidth * geometry.worldHeight
    }

    /// Net floor area available to people, in m² (gross minus obstacle footprints).
    /// Note: a first-order model — overlapping obstacles would double-count.
    public var netFloorArea: Double {
        max(0, grossFloorArea - obstacles.reduce(0) { $0 + $1.area })
    }

    /// Simulable only with a positive grid and at least one exit.
    public var isValid: Bool {
        !geometry.size.isEmpty && !exits.isEmpty
    }
}
