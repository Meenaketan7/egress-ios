// The **locked render / concurrency contract** (build plan §A.3). The simulation produces
// one immutable, `Sendable` `SimulationSnapshot` per frame; the SwiftUI canvas consumes it
// and nothing else. Locking this shape in S0 is what lets the app be built and demoed
// against `MockSimulation` and later swapped to the real engine with no UI change.

import Foundation

// MARK: - AgentRender

/// The slim per-agent state the renderer needs: a position plus the three channels that
/// drive a sprite's tint, glyph and gait. Deliberately smaller than the full simulation
/// agent (no forces, traits, or path memory) — this is the value that crosses the
/// isolation boundary every frame, so it stays cheap to copy.
public struct AgentRender: Identifiable, Sendable, Equatable {
    public let id: Int
    /// Position in metres (world space).
    public var position: Vec2
    public var emotion: EmotionalState
    public var mobility: MobilityClass
    public var status: AgentStatus

    public init(
        id: Int,
        position: Vec2,
        emotion: EmotionalState,
        mobility: MobilityClass,
        status: AgentStatus
    ) {
        self.id = id
        self.position = position
        self.emotion = emotion
        self.mobility = mobility
        self.status = status
    }
}

// MARK: - HazardSnapshot

/// Fire and smoke cell states for one frame (flood was cut in v3). Sparse by cell — early
/// runs touch only a handful of cells; a dense grid can replace the storage behind the same
/// type if profiling ever demands it, without changing the contract.
public struct HazardSnapshot: Sendable, Equatable {
    /// Cell → fire intensity, 0…1.
    public var fire: [GridCoord: Double]
    /// Cell → smoke opacity, 0…1.
    public var smoke: [GridCoord: Double]

    public init(fire: [GridCoord: Double] = [:], smoke: [GridCoord: Double] = [:]) {
        self.fire = fire
        self.smoke = smoke
    }

    /// No hazard present — the pre-ignition state.
    public static let none = HazardSnapshot()

    public var isEmpty: Bool { fire.isEmpty && smoke.isEmpty }
}

// MARK: - LiveMetrics

/// The HUD's live readouts — cheap counters recomputed each tick. Distinct from the
/// end-of-run `Metrics` (peak density-seconds, clearance, score inputs) that arrive in S2.
public struct LiveMetrics: Sendable, Equatable {
    public var elapsed: TimeInterval
    public var activeCount: Int
    public var evacuatedCount: Int
    public var casualtyCount: Int
    /// Worst per-cell density this frame, persons·m⁻².
    public var worstDensity: Double
    /// Fraction of the population that has left the floor, 0…1.
    public var fractionOut: Double

    public init(
        elapsed: TimeInterval,
        activeCount: Int,
        evacuatedCount: Int,
        casualtyCount: Int,
        worstDensity: Double,
        fractionOut: Double
    ) {
        self.elapsed = elapsed
        self.activeCount = activeCount
        self.evacuatedCount = evacuatedCount
        self.casualtyCount = casualtyCount
        self.worstDensity = worstDensity
        self.fractionOut = fractionOut
    }

    public static let zero = LiveMetrics(
        elapsed: 0, activeCount: 0, evacuatedCount: 0,
        casualtyCount: 0, worstDensity: 0, fractionOut: 0
    )
}

// MARK: - SimulationSnapshot

/// One frame of the simulation, as the renderer sees it. Value-typed and `Sendable` so it
/// can be handed from the (non-`@MainActor`) simulation to the UI without data races.
public struct SimulationSnapshot: Sendable, Equatable {
    public let time: TimeInterval
    public let agents: [AgentRender]
    public let hazards: HazardSnapshot
    public let density: DensityGrid
    public let live: LiveMetrics

    public init(
        time: TimeInterval,
        agents: [AgentRender],
        hazards: HazardSnapshot,
        density: DensityGrid,
        live: LiveMetrics
    ) {
        self.time = time
        self.agents = agents
        self.hazards = hazards
        self.density = density
        self.live = live
    }

    /// An empty pre-run snapshot sized to a venue, so the canvas has something to draw
    /// before the first `step`.
    public static func empty(size: GridSize) -> SimulationSnapshot {
        SimulationSnapshot(
            time: 0,
            agents: [],
            hazards: .none,
            density: DensityGrid(size: size),
            live: .zero
        )
    }
}
