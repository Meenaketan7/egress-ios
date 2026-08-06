import Foundation

// MARK: - EmoteKind

/// A momentary feeling a person shows above their head (design §3 emote layer). Shape-only and
/// meant to read in greyscale — the *glyph* carries the meaning, never colour. Six states, each
/// emergent from what the agent is doing, not scripted.
public enum EmoteKind: String, Sendable, Equatable, CaseIterable, Codable {
    /// `!` — the first shock: an agent has just turned panicked.
    case astonished
    /// `?` — hesitation: an uneasy agent has slowed in open space, unsure where to go.
    case confused
    /// spiral — stuck: an agent has stalled inside a crowd and can't make progress.
    case frustrated
    /// droplet — a living agent trapped against the fire, in real danger.
    case distressed
    /// `~` — relief: an agent has reached the threshold of an exit.
    case relieved
    /// chevrons — resolve: staff holding steady beside a panicking neighbour.
    case resolute

    /// When more than the on-screen cap want to show at once, the most urgent win. Public because the
    /// renderer uses it to pick which glyphs survive the on-screen cap.
    public var priority: Int {
        switch self {
        case .distressed: 5
        case .astonished: 4
        case .relieved: 3
        case .resolute: 3
        case .frustrated: 2
        case .confused: 1
        }
    }
}

// MARK: - EmoteInput

/// The slim per-agent view the `EmoteTracker` reads each frame — everything it needs to infer a
/// feeling, and nothing physical it could feed back into. Assembled by the simulation from state it
/// already computes (emotion, density, fire/exit proximity), so producing emotes never perturbs the
/// deterministic physics.
struct EmoteInput {
    let id: Int
    let position: Vec2
    let mobility: MobilityClass
    let emotion: EmotionalState
    let status: AgentStatus
    /// Current speed in m/s — a near-zero value in a crowd is a stall.
    let speed: Double
    /// Smoothed crowd density in the agent's cell.
    let localDensity: Double
    /// The agent is standing in or beside active fire.
    let nearFire: Bool
    /// The agent is within a stride of an exit doorway.
    let nearExit: Bool
}

// MARK: - EmoteTracker

/// Infers each agent's momentary emote from frame-to-frame changes, holding it briefly so a glyph
/// pops and fades rather than flickering. A pure observer — like `updateEmotions`, it reads sim state
/// and never writes back, so the crowd's motion (and every existing test) is unaffected. Deterministic:
/// the same sequence of inputs always yields the same emotes.
struct EmoteTracker {
    /// How long (sim seconds) a glyph lingers after its trigger before clearing.
    static let lifetime: TimeInterval = 1.6
    /// Below this speed (m/s) an agent counts as stalled / hesitating.
    static let stallSpeed = 0.12
    /// A staff member within this distance (m) of a panicked person reads as "calming" them.
    static let staffReach = 1.6

    private var previousEmotion: [Int: EmotionalState] = [:]
    private var active: [Int: (kind: EmoteKind, born: TimeInterval)] = [:]

    /// Advance the tracker one frame and return the emote currently shown for each agent (agents with
    /// no glyph are absent from the map).
    mutating func update(agents: [EmoteInput], time: TimeInterval) -> [Int: EmoteKind] {
        // Expire glyphs whose lifetime has run out.
        for (id, entry) in active where time - entry.born >= Self.lifetime {
            active[id] = nil
        }

        let panickedPositions = agents
            .filter { $0.emotion == .panicked && $0.status.isActive }
            .map(\.position)

        for agent in agents {
            if let kind = trigger(for: agent, panicked: panickedPositions) {
                // A fresh trigger replaces a weaker (or expired) glyph; a stronger one already showing wins.
                if let current = active[agent.id], current.kind.priority > kind.priority,
                   time - current.born < Self.lifetime {
                    // keep the stronger current glyph
                } else {
                    active[agent.id] = (kind, time)
                }
            }
            previousEmotion[agent.id] = agent.emotion
        }

        return active.mapValues(\.kind)
    }

    /// The single emote an agent's current state calls for, in priority order, or `nil`. Only living
    /// agents emote — casualties and the evacuated have left the drawn crowd.
    private func trigger(for agent: EmoteInput, panicked: [Vec2]) -> EmoteKind? {
        guard agent.status.isActive else { return nil }
        let wasPanicked = previousEmotion[agent.id] == .panicked
        let stalled = agent.speed < Self.stallSpeed

        // Distressed — a living agent pinned against the fire is the most urgent read.
        if agent.nearFire, agent.emotion == .panicked {
            return .distressed
        }
        // Astonished — the instant the alarm/hazard tips someone into panic.
        if agent.emotion == .panicked, !wasPanicked {
            return .astonished
        }
        // Relieved — reaching the threshold of an exit.
        if agent.nearExit {
            return .relieved
        }
        // Resolute — staff standing their ground next to a panicking neighbour.
        if agent.mobility == .staff, agent.emotion != .panicked,
           panicked.contains(where: { $0.distance(to: agent.position) <= Self.staffReach }) {
            return .resolute
        }
        // Frustrated — stalled inside a crowd, going nowhere.
        if stalled, agent.emotion != .calm, agent.localDensity >= SafetyStandards.densityComfortable {
            return .frustrated
        }
        // Confused — uneasy and hesitating in open space (not a jam).
        if stalled, agent.emotion == .uneasy, agent.localDensity < SafetyStandards.densityComfortable {
            return .confused
        }
        return nil
    }
}
