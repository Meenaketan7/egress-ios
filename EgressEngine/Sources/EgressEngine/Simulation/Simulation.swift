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
    /// The navigation field. Rebuilt mid-run when fire changes which cells are passable, so the crowd
    /// reroutes around new flames (Req 3).
    private var field: FlowField
    private let wallField: WallField
    private let timeCap: TimeInterval

    /// Walls + obstacles — the impassable set before any fire. Fire cells are unioned on for rerouting.
    private let baseBlocked: Set<GridCoord>
    /// The exit cells the flow field seeds at cost 0.
    private let exits: [GridCoord]

    /// Fire and smoke for this run, advanced on their own 15 Hz clock (§2.7).
    private var hazards: HazardField
    /// The active-fire set currently baked into `field` — a rebuild trigger when it changes.
    private var blockedByFire: Set<GridCoord> = []
    /// Seconds each injured agent has spent down — fatal at `FIRE_LETHAL_DELAY`, keyed by agent id.
    private var injuryElapsed: [Int: Double] = [:]
    /// One RNG stream for the whole run (spawn + hazard spread) — identical seed ⇒ identical run.
    private var rng: SeededRNG

    /// This run's panicked-agent speed multiplier (§2.6), from config — the faster-is-slower knob.
    /// Default (`SimConstants.panicArousal`) leaves runs byte-identical to before it was injectable.
    private let panicSpeed: Double

    /// The editor-placed ignition cells, kept so the run-start ignition events can be logged on the
    /// first step (§A.5). Empty for a fire-free run.
    private let ignitionCells: [GridCoord]
    /// One-shot guards so the run-start markers and the single `simEnded` each fire exactly once.
    private var startEmitted = false
    private var endEmitted = false

    private var agents: [Agent]
    private var time: TimeInterval = 0
    private var accumulator: Double = 0

    /// Run analysis folded across the whole simulation (§2.8) — clearance, peak density, at-risk
    /// dwell. The verdict and Safety Score read this once the run resolves.
    public private(set) var metrics: Metrics

    /// The run-lifecycle event log (§A.5) — what happened and when, feeding the timeline scrubber and
    /// the AI digest. Emission never draws RNG or mutates sim state, so the log is a pure observer and
    /// runs stay deterministic.
    public private(set) var eventLog = RunEventLog()

    /// Live in-sim escalation (§3.3) — watches the running metrics each frame and raises anti-spammed
    /// banners. Reads sim state only; never feeds back, so runs stay deterministic.
    private var escalation = EscalationTracker()
    /// Escalations raised so far this run, in order — the HUD reads the latest for its banner and the
    /// timeline draws them all; each also mirrors into `eventLog`.
    public private(set) var escalations: [EscalationTracker.Escalation] = []

    /// The most recent frame's smoothed density, cached by `step` so `snapshot` needn't recompute it.
    private var cachedDensity: DensityGrid?

    public init(venue: VenueModel, config: SimulationConfig) {
        geometry = venue.geometry
        let size = venue.geometry.size
        let blocked = BlockedCells.of(venue)
        baseBlocked = blocked
        let exitCells = Self.exitCells(venue.exits, in: venue.geometry)
        exits = exitCells
        let navigation = FlowField(size: size, blocked: blocked, exits: exitCells)
        field = navigation
        wallField = WallField(size: size, cellSize: venue.geometry.cellSize, blocked: blocked)

        // Cap = clamp(3 × the venue's egress target, 300, 600) s (§2.8) — headroom to observe a jam
        // that misses the target, bounded so even a gridlocked run still terminates.
        let target = venue.type.clearanceTarget
        timeCap = min(max(3 * target, 300), 600)

        rng = SeededRNG(seed: config.seed)
        panicSpeed = config.panicSpeed
        agents = AgentSpawner.spawn(count: config.agentCount, in: venue.geometry, field: navigation, rng: &rng)
        metrics = Metrics(spawnedCount: agents.count, clearanceTarget: target, timeCap: timeCap)

        // Fire only catches on reachable floor; seed it at the editor-placed ignition points (§2.7).
        let flammable = (0 ..< size.count).map { navigation.isReachable(size.coord(atIndex: $0)) }
        let ignition = config.ignition.map { venue.geometry.cell(for: $0) }
        ignitionCells = ignition
        hazards = HazardField(size: size, flammable: flammable, ignition: ignition)
    }

    public var isComplete: Bool {
        time >= timeCap || agents.allSatisfy { !$0.status.isActive }
    }

    public func step(dt: Double) {
        let start = time
        emitRunStartEventsIfNeeded()
        let frame = min(dt, SimConstants.maxFrame)

        // Hazards run on their own 15 Hz clock; when fire changes the passable set, reroute the crowd.
        hazards.advance(by: frame, rng: &rng)
        rerouteAroundFire()

        accumulator += frame
        while accumulator >= SimConstants.substep {
            advance(by: SimConstants.substep)
            accumulator -= SimConstants.substep
            time += SimConstants.substep
        }
        // Fold this frame into the run metrics once, using the time actually advanced. A frame too
        // short to cross a substep boundary advances nothing, so there is nothing to record.
        let advanced = time - start
        guard advanced > 0 else { return }
        resolveHazardCasualties(dt: advanced)
        let density = currentDensity()
        cachedDensity = density
        updateEmotions(density: density)
        metrics.record(time: time, dt: advanced, density: density, activeCells: activeCells())
        evaluateEscalation(density: density)

        // The single end-of-run marker, logged the moment the run first resolves.
        if isComplete, !endEmitted {
            endEmitted = true
            eventLog.record(.simEnded, at: time, detail: endReason())
        }
    }

    public func snapshot() -> SimulationSnapshot {
        let density = cachedDensity ?? currentDensity()
        return SimulationSnapshot(
            time: time,
            agents: agents.map(\.render),
            hazards: hazards.snapshot,
            density: density,
            live: liveMetrics(density: density)
        )
    }

    /// The smoothed crowd density for this frame. Active bodies and casualties both occupy floor
    /// space; evacuated agents don't. Rebuilt once per `snapshot` — i.e. once per rendered frame.
    private func currentDensity() -> DensityGrid {
        let bodies = agents.compactMap { $0.status.isActive || $0.status.isCasualty ? $0.position : nil }
        return DensityGrid.sampled(positions: bodies, in: geometry)
    }

    /// Each still-moving agent paired with the grid cell it occupies — the per-frame input the metrics
    /// fold needs to attribute at-risk dwell. Evacuated and casualty agents are excluded: neither is
    /// still trying to get out.
    private func activeCells() -> [(id: Int, cell: GridCoord)] {
        agents.compactMap { agent in
            agent.status.isActive ? (id: agent.id, cell: geometry.cell(for: agent.position)) : nil
        }
    }

    /// Rebuild the flow field when fire has changed which cells are passable, so agents pick up new
    /// downhill directions and detour around flames (Req 3). A cheap BFS that only fires on an actual
    /// change in the active-fire set — so a fire-free run never rebuilds.
    private func rerouteAroundFire() {
        let activeFire = hazards.activeFire
        guard activeFire != blockedByFire else { return }
        blockedByFire = activeFire
        field = FlowField(size: geometry.size, blocked: baseBlocked.union(activeFire), exits: exits)
        eventLog.record(.flowFieldRecomputed, at: time, detail: "rerouted around fire")
    }

    /// Turn fire contact into casualties (§2.7): an agent in an active-fire cell is injured at once and
    /// dies after `FIRE_LETHAL_DELAY`. The downed stop steering but stay as soft obstacles — they still
    /// count toward density and repulsion, so a fallen body worsens the jam, as in reality.
    private func resolveHazardCasualties(dt: Double) {
        let fire = hazards.activeFire
        guard !fire.isEmpty else { return }
        for i in agents.indices {
            switch agents[i].status {
            case .active:
                let cell = geometry.cell(for: agents[i].position)
                if fire.contains(cell) {
                    agents[i].status = .injured
                    agents[i].velocity = .zero
                    injuryElapsed[agents[i].id] = 0
                    metrics.recordCasualty()
                    eventLog.record(.agentInjured, at: time, location: cell, agentID: agents[i].id, detail: "fire")
                }
            case .injured:
                injuryElapsed[agents[i].id, default: 0] += dt
                if injuryElapsed[agents[i].id, default: 0] >= SimConstants.fireLethalDelay {
                    agents[i].status = .dead
                    eventLog.record(
                        .agentKilled, at: time,
                        location: geometry.cell(for: agents[i].position), agentID: agents[i].id, detail: "fire"
                    )
                }
            case .evacuated, .dead:
                break
            }
        }
    }

    /// Raise each active agent's arousal band from what it can currently sense (§2.6): standing in or on
    /// an active-fire cell, or inside an at-risk-density cell, tips it to panicked; a merely congested cell
    /// makes it uneasy; otherwise calm. Panic feeds `SimConstants.arousalFactor`, so a packed bottleneck
    /// speeds everyone up, contact and friction climb, and flow *falls* — faster-is-slower, emergent not
    /// scripted (§2.2). A pure observer of density + fire: no RNG, no feedback, so runs stay deterministic.
    private func updateEmotions(density: DensityGrid) {
        let fire = hazards.activeFire
        for i in agents.indices where agents[i].status.isActive {
            let cell = geometry.cell(for: agents[i].position)
            let local = density.value(at: cell)
            let nearFire = fire.contains(cell)
            agents[i].emotion = (nearFire || local >= SafetyStandards.densityAtRisk) ? .panicked
                : local >= SafetyStandards.densityComfortable ? .uneasy
                : .calm
        }
    }

    /// Log the run-start markers once: the alarm that begins the evacuation and every editor-placed
    /// ignition. Both are t = 0 in this model — the crowd reacts to the alarm immediately.
    private func emitRunStartEventsIfNeeded() {
        guard !startEmitted else { return }
        startEmitted = true
        eventLog.record(.alarmTriggered, at: time)
        for cell in ignitionCells {
            eventLog.record(.ignition, at: time, location: cell)
        }
    }

    /// Why the run stopped, for the `simEnded` event: everyone reached an exit, the clock hit the cap,
    /// or the only ones left are casualties.
    private func endReason() -> String {
        if agents.allSatisfy(\.status.hasEvacuated) { return "all evacuated" }
        if time >= timeCap { return "time cap" }
        return "run ended with casualties"
    }

    /// Feed this frame's live metrics to the escalation tracker and, when it raises a banner, mirror it
    /// into the log. Read-only over the sim — no feedback into the physics — so runs stay deterministic.
    private func evaluateEscalation(density: DensityGrid) {
        let signals = EscalationTracker.Signals(
            peakDensity: density.peak,
            exitBlocked: exits.contains { blockedByFire.contains($0) },
            casualties: metrics.casualties
        )
        guard let raised = escalation.update(time: time, signals: signals) else { return }
        escalations.append(raised)
        recordEscalation(raised, peakCell: density.peakCell, peakDensity: density.peak)
    }

    /// Mirror a live escalation into the run log (§3.3): density rungs become threshold-crossing events;
    /// a cut-off exit its own event. The first casualty is already logged as `agentInjured`, so its
    /// banner needs no duplicate entry.
    private func recordEscalation(_ raised: EscalationTracker.Escalation, peakCell: GridCoord?, peakDensity: Double) {
        switch raised.band {
        case .congestion, .bottleneck, .crush:
            eventLog.record(
                .densityThresholdCrossed, at: raised.time,
                location: peakCell, magnitude: peakDensity, detail: raised.band.rawValue
            )
        case .exitBlocked:
            eventLog.record(.exitBlocked, at: raised.time, detail: "an exit is blocked by fire")
        case .casualty:
            break
        }
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
            let desiredSpeed = agent.baseSpeed * SimConstants.arousalFactor(agent.emotion, panic: panicSpeed)
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

        private func liveMetrics(density: DensityGrid) -> LiveMetrics {
        let evacuated = agents.lazy.filter { $0.status.hasEvacuated }.count
        let active = agents.lazy.filter { $0.status.isActive }.count
        return LiveMetrics(
            elapsed: time,
            activeCount: active,
            evacuatedCount: evacuated,
            casualtyCount: agents.lazy.filter { $0.status.isCasualty }.count,
            worstDensity: density.peak,
            fractionOut: agents.isEmpty ? 0 : Double(evacuated) / Double(agents.count)
        )
    }

    /// Rasterises each exit doorway (a metre segment, often on the far edge) into the grid cells the
    /// flow field seeds at cost 0, clamped so an edge doorway lands on the nearest in-bounds row.
    /// `public` so the editor can seed an identical `FlowField` to pre-check that its authored floor
    /// actually drains — the "simulable" indicator must match how the real run seeds exits, exactly.
    public static func exitCells(_ exits: [Exit], in geometry: GridGeometry) -> [GridCoord] {
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