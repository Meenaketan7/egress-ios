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
    /// Standing-water flood zones — static impassable regions the crowd routes around (§2.7 hazards).
    public var water: [WaterZone]
    /// Extra impassable cells beyond the walls/obstacles/water — the free-form editor puts the room's
    /// *exterior* here (see `RoomEnclosure`) so only the walls' enclosed interior is floor. Empty by
    /// default, so a venue built without it behaves exactly as if the whole grid were floor.
    public var blockedCells: Set<GridCoord>
    public var decor: [DecorTile]

    public init(
        id: Int,
        name: String,
        type: VenueType,
        geometry: GridGeometry,
        walls: [Wall] = [],
        exits: [Exit] = [],
        obstacles: [Obstacle] = [],
        water: [WaterZone] = [],
        blockedCells: Set<GridCoord> = [],
        decor: [DecorTile] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.geometry = geometry
        self.walls = walls
        self.exits = exits
        self.obstacles = obstacles
        self.water = water
        self.blockedCells = blockedCells
        self.decor = decor
    }

    /// Gross floor area, in m² (before subtracting obstacles).
    public var grossFloorArea: Double {
        geometry.worldWidth * geometry.worldHeight
    }

    /// Net floor area available to people, in m² (gross minus obstacle footprints, minus any
    /// out-of-room `blockedCells` so a walls-enclosed shape reports its real floor, not the bounding
    /// box). A first-order model — overlapping obstacles would double-count.
    public var netFloorArea: Double {
        let cell = geometry.cellSize
        let exterior = Double(blockedCells.count) * cell * cell
        return max(0, grossFloorArea - exterior - obstacles.reduce(0) { $0 + $1.area })
    }

    /// Simulable only with a positive grid and at least one exit.
    public var isValid: Bool {
        !geometry.size.isEmpty && !exits.isEmpty
    }
}
