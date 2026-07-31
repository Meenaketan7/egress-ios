import Foundation

/// A deterministic stand-in for the real `Simulation`, shipped in S0 so Dev B can build the
/// whole canvas/HUD/gesture stack before the physics exists. It is intentionally *not*
/// physically accurate: agents drift straight toward the nearest exit, and a small fire
/// blooms after a few seconds so every channel of `SimulationSnapshot` — agents, density,
/// hazards, live metrics — carries real, animated data. It conforms to `SimulationRunning`,
/// so swapping in the real engine at S1 exit is a one-line change above this file.
public final class MockSimulation: SimulationRunning {
    private let venue: VenueModel
    private let config: SimulationConfig
    private let target: Vec2 // the exit everyone heads for
    private let timeCap: TimeInterval = 300

    private var time: TimeInterval = 0
    private var agents: [AgentRender]
    private var density: DensityGrid
    private var hazards: HazardSnapshot = .none

    public init(venue: VenueModel, config: SimulationConfig) {
        self.venue = venue
        self.config = config
        target = venue.exits.first?.center
            ?? Vec2(venue.geometry.worldWidth / 2, venue.geometry.worldHeight)
        density = DensityGrid(size: venue.geometry.size)

        var rng = SeededRNG(seed: config.seed)
        let mix: [MobilityClass] = [.adult, .adult, .adult, .child, .elderly, .wheelchair, .staff]
        agents = (0 ..< config.agentCount).map { id in
            AgentRender(
                id: id,
                position: Vec2(
                    .random(in: 0.5 ... max(0.5, venue.geometry.worldWidth - 0.5), using: &rng),
                    .random(in: 0.5 ... max(0.5, venue.geometry.worldHeight - 0.5), using: &rng)
                ),
                emotion: .calm,
                mobility: mix.randomElement(using: &rng) ?? .adult,
                status: .active
            )
        }
    }

    public var isComplete: Bool {
        time >= timeCap || agents.allSatisfy { !$0.status.isActive }
    }

    public func step(dt: Double) {
        let clamped = min(dt, 1.0 / 30.0)
        time += clamped

        updateHazards()
        for i in agents.indices where agents[i].status.isActive {
            let toExit = target - agents[i].position
            let speed = baseSpeed(agents[i].mobility) * (agents[i].emotion == .panicked ? 1.5 : 1.0)
            agents[i].position += toExit.normalized * speed * clamped
            if toExit.length < 0.4 { agents[i].status = .evacuated }
        }
        rebuildDensity()
        updateEmotions()
    }

    public func snapshot() -> SimulationSnapshot {
        SimulationSnapshot(time: time, agents: agents, hazards: hazards, density: density, live: liveMetrics())
    }

    // MARK: - Internals

    private func baseSpeed(_ m: MobilityClass) -> Double {
        switch m {
        case .adult, .staff: 1.3
        case .child: 0.9
        case .elderly: 0.7
        case .wheelchair: 0.8
        }
    }

    /// A tiny fire seed that ignites at 5 s in a corner and grows a small smoke halo — enough
    /// to exercise the hazard-render channel, not a real cellular automaton.
    private func updateHazards() {
        guard time >= 5 else { return }
        let fireOrigin = venue.geometry.cell(for: Vec2(1, 1))
        let intensity = min(1, (time - 5) / 20)
        var fire: [GridCoord: Double] = [:]
        var smoke: [GridCoord: Double] = [:]
        let reach = Int((time - 5) / 4) // grows one ring every 4 s
        for dy in -reach ... reach {
            for dx in -reach ... reach {
                let c = GridCoord(fireOrigin.x + dx, fireOrigin.y + dy)
                guard venue.geometry.size.contains(c) else { continue }
                let ring = max(abs(dx), abs(dy))
                if ring == 0 { fire[c] = intensity }
                smoke[c] = max(0, intensity - Double(ring) * 0.15)
            }
        }
        hazards = HazardSnapshot(fire: fire, smoke: smoke)
    }

    /// Coarse p·m⁻² field: count active agents per 1 m² block (4×4 cells), then spread that
    /// value across the block's cells. Blocky, but a faithful stand-in for the glow layer.
    private func rebuildDensity() {
        var grid = DensityGrid(size: venue.geometry.size)
        let block = 4 // 1 m at 0.25 m cells
        var counts: [GridCoord: Int] = [:]
        for a in agents where a.status.isActive {
            let cell = venue.geometry.cell(for: a.position)
            counts[GridCoord(cell.x / block, cell.y / block), default: 0] += 1
        }
        for (b, n) in counts {
            let personsPerSquareMetre = Double(n) // block is 1 m²
            for dy in 0 ..< block {
                for dx in 0 ..< block {
                    grid.set(personsPerSquareMetre, at: GridCoord(b.x * block + dx, b.y * block + dy))
                }
            }
        }
        density = grid
    }

    private func updateEmotions() {
        for i in agents.indices where agents[i].status.isActive {
            let local = density.value(at: venue.geometry.cell(for: agents[i].position))
            let nearFire = hazards.fire.keys.contains(venue.geometry.cell(for: agents[i].position))
            agents[i].emotion = (nearFire || local >= 5) ? .panicked
                : local >= 1.8 ? .uneasy
                : .calm
        }
    }

    private func liveMetrics() -> LiveMetrics {
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
}
