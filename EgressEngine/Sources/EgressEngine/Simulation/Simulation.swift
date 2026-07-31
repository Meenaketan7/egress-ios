import Foundation

/// The real crowd engine (S1). Builds the static navigation once — impassable set → flow field —
/// spawns the crowd, then each frame drives every active agent downhill toward the nearest exit
/// under a Helbing social force (drive + pedestrian repulsion/contact/friction), integrated with
/// semi-implicit Euler in fixed substeps. Conforms to `SimulationRunning`, so it drops into the
/// app in place of `MockSimulation` with no change above that protocol.
///
/// S1 scope: the driving term, the pedestrian force, and hard wall sliding. The *soft* wall force
/// (needs the obstacle distance field), density, hazards and emotion dynamics arrive later.
public final class Simulation: SimulationRunning {
    private let geometry: GridGeometry
    private let field: FlowField
    private let wallField: WallField
    private let emptyDensity: DensityGrid
    private let timeCap: TimeInterval = 300

    private var agents: [Agent]
    private var time: TimeInterval = 0
    private var accumulator: Double = 0

    public init(venue: VenueModel, config: SimulationConfig) {
        geometry = venue.geometry
        let blocked = BlockedCells.of(venue)
        let exits = Self.exitCells(venue.exits, in: venue.geometry)
        field = FlowField(size: venue.geometry.size, blocked: blocked, exits: exits)
        wallField = WallField(size: venue.geometry.size, cellSize: venue.geometry.cellSize, blocked: blocked)
        emptyDensity = DensityGrid(size: venue.geometry.size)

        var rng = SeededRNG(seed: config.seed)
        agents = AgentSpawner.spawn(count: config.agentCount, in: venue.geometry, field: field, rng: &rng)
    }

    public var isComplete: Bool {
        time >= timeCap || agents.allSatisfy { !$0.status.isActive }
    }

    public func step(dt: Double) {
        accumulator += min(dt, SimConstants.maxFrame)
        while accumulator >= SimConstants.substep {
            advance(by: SimConstants.substep)
            accumulator -= SimConstants.substep
            time += SimConstants.substep
        }
    }

    public func snapshot() -> SimulationSnapshot {
        SimulationSnapshot(
            time: time,
            agents: agents.map(\.render),
            hazards: .none,
            density: emptyDensity,
            live: liveMetrics()
        )
    }

    // MARK: - Integration

    /// One fixed physics substep. Forces are read from a start-of-substep snapshot (`previous`) so
    /// every agent sees the same world — an order-independent (Jacobi) update, which keeps the run
    /// reproducible regardless of agent iteration order.
    private func advance(by step: Double) {
        let previous = agents
        let hash = SpatialHash(positions: previous.map(\.position), binSize: SimConstants.interactionRange)

        for i in agents.indices where previous[i].status.isActive {
            let agent = previous[i]
            let cell = geometry.cell(for: agent.position)

            // A doorway cell is the only cell with cost 0 — standing on one means safely out.
            if field.cost(at: cell) == 0 {
                agents[i].status = .evacuated
                agents[i].velocity = .zero
                continue
            }

            // Driving term + pedestrian force, clamped to A_MAX for stability.
            let desiredSpeed = agent.baseSpeed * SimConstants.arousalFactor(agent.emotion)
            let desiredVelocity = field.direction(at: cell) * desiredSpeed
            var acceleration = (desiredVelocity - agent.velocity) / SimConstants.tau
            acceleration += pedestrianAcceleration(on: i, in: previous, using: hash)
            acceleration += wallAcceleration(for: agent, at: cell)
            acceleration = capped(acceleration, at: SimConstants.maxAcceleration)

            var velocity = capped(agent.velocity + acceleration * step, at: SimConstants.maxSpeed)

            // Move axis-by-axis, cancelling any component that would enter a wall (hard wall slide).
            var next = agent.position
            let moveX = velocity.x * step
            if isOpen(geometry.cell(for: Vec2(next.x + moveX, next.y))) {
                next.x += moveX
            } else {
                velocity.x = 0
            }
            let moveY = velocity.y * step
            if isOpen(geometry.cell(for: Vec2(next.x, next.y + moveY))) {
                next.y += moveY
            } else {
                velocity.y = 0
            }

            agents[i].velocity = velocity
            agents[i].position = clampToWorld(next)
        }
    }

    /// Helbing pedestrian term (§2.2): a soft exponential repulsion that is always on, plus body and
    /// tangential-friction contact terms once two people actually overlap. Summed over neighbours
    /// within `R_INT`, found via the spatial hash. Evacuated agents exert nothing; casualties remain
    /// soft obstacles.
    private func pedestrianAcceleration(on index: Int, in population: [Agent], using hash: SpatialHash) -> Vec2 {
        let agent = population[index]
        var force = Vec2.zero
        for j in hash.candidates(near: agent.position, radius: SimConstants.interactionRange) where j != index {
            let neighbour = population[j]
            guard neighbour.status.isActive || neighbour.status.isCasualty else { continue }
            let offset = agent.position - neighbour.position
            let distance = offset.length
            guard distance > 1e-9, distance < SimConstants.interactionRange else { continue }
            let normal = offset / distance
            let overlap = agent.radius + neighbour.radius - distance
            force += SimConstants.pedStrength * exp(overlap / SimConstants.pedFalloff) * normal
            if overlap > 0 {
                let tangent = Vec2(-normal.y, normal.x)
                force += SimConstants.bodyStiffness * overlap * normal
                let tangentialApproach = (neighbour.velocity - agent.velocity).dot(tangent)
                force += SimConstants.frictionStiffness * overlap * tangentialApproach * tangent
            }
        }
        return force
    }

    /// Helbing wall term (§2.2): the same soft-repulsion-plus-contact shape as the pedestrian force,
    /// but against the nearest wall (from `WallField`) with a stationary "neighbour" — so the
    /// friction opposes the agent's velocity tangent to the wall. Zero where no wall is in range,
    /// which for a wall-less venue is everywhere.
    private func wallAcceleration(for agent: Agent, at cell: GridCoord) -> Vec2 {
        let distance = wallField.distance(at: cell)
        guard distance < SimConstants.interactionRange else { return .zero }
        let normal = wallField.normal(at: cell)
        guard normal != .zero else { return .zero }

        let overlap = agent.radius - distance
        var force = SimConstants.wallStrength * exp(overlap / SimConstants.wallFalloff) * normal
        if overlap > 0 {
            force += SimConstants.bodyStiffness * overlap * normal
            let tangent = Vec2(-normal.y, normal.x)
            let tangentialApproach = (Vec2.zero - agent.velocity).dot(tangent)
            force += SimConstants.frictionStiffness * overlap * tangentialApproach * tangent
        }
        return force
    }

    // MARK: - Helpers

    /// A cell an agent may stand in: reachable ⇒ in-bounds, not a wall or obstacle, connected to an exit.
    private func isOpen(_ cell: GridCoord) -> Bool {
        field.isReachable(cell)
    }

    /// Keeps a position inside the venue so a boundary-facing gradient can never push an agent off the grid.
    private func clampToWorld(_ point: Vec2) -> Vec2 {
        let inset = 1e-6
        return Vec2(
            min(max(point.x, 0), geometry.worldWidth - inset),
            min(max(point.y, 0), geometry.worldHeight - inset)
        )
    }

    /// A vector limited to a maximum magnitude — the A_MAX / V_MAX clamps that keep stiff contact
    /// forces from exploding in a single step.
    private func capped(_ vector: Vec2, at maximum: Double) -> Vec2 {
        let magnitude = vector.length
        return magnitude > maximum ? vector / magnitude * maximum : vector
    }

    private func liveMetrics() -> LiveMetrics {
        let evacuated = agents.lazy.filter { $0.status.hasEvacuated }.count
        let active = agents.lazy.filter { $0.status.isActive }.count
        return LiveMetrics(
            elapsed: time,
            activeCount: active,
            evacuatedCount: evacuated,
            casualtyCount: agents.lazy.filter { $0.status.isCasualty }.count,
            worstDensity: emptyDensity.peak,
            fractionOut: agents.isEmpty ? 0 : Double(evacuated) / Double(agents.count)
        )
    }

    /// Rasterises each exit doorway (a metre segment, often on the far edge) into the grid cells the
    /// flow field seeds at cost 0, clamped so an edge doorway lands on the nearest in-bounds row.
    private static func exitCells(_ exits: [Exit], in geometry: GridGeometry) -> [GridCoord] {
        let size = geometry.size
        guard !size.isEmpty else { return [] }
        var cells: Set<GridCoord> = []
        let sampleStep = geometry.cellSize * 0.5
        for exit in exits {
            let span = exit.a.distance(to: exit.b)
            let samples = max(1, Int((span / sampleStep).rounded(.up)))
            for i in 0 ... samples {
                let t = Double(i) / Double(samples)
                let point = exit.a + (exit.b - exit.a) * t
                let raw = geometry.cell(for: point)
                cells.insert(GridCoord(
                    min(max(raw.x, 0), size.width - 1),
                    min(max(raw.y, 0), size.height - 1)
                ))
            }
        }
        return Array(cells)
    }
}