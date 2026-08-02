import Foundation

/// The five live in-sim escalation bands (§3.3) — the amber/red banners RALLY raises *during* a run,
/// distinct from the end-of-run verdict. Density climbs through three rungs; an exit can be cut off by
/// a hazard; the first casualty is its own alert.
public enum EscalationBand: String, Sendable, CaseIterable {
    case congestion  // density approaching the at-risk band
    case bottleneck  // density at the at-risk band
    case crush       // density in the crush band
    case exitBlocked // a hazard has reached an exit
    case casualty    // the first person is down

    /// Firing priority when several bands are pending in one frame — the most severe fires first.
    var severity: Int {
        switch self {
        case .congestion: 1
        case .bottleneck: 2
        case .exitBlocked: 3
        case .crush: 4
        case .casualty: 5
        }
    }

    /// The density rungs, low to high. Crossing a higher rung surpasses the lower ones, so they are
    /// not announced afterwards.
    static let densityLadder: [EscalationBand] = [.congestion, .bottleneck, .crush]

    /// Whether this band's trigger is true for the given live signals.
    func isActive(in signals: EscalationTracker.Signals) -> Bool {
        switch self {
        case .congestion: signals.peakDensity >= VerdictConstants.escalationApproachDensity
        case .bottleneck: signals.peakDensity >= SafetyStandards.densityAtRisk
        case .crush: signals.peakDensity >= SafetyStandards.densityCrush
        case .exitBlocked: signals.exitBlocked
        case .casualty: signals.casualties >= 1
        }
    }
}

/// Live in-sim escalation (§3.3): each frame it reads the running metrics and decides whether to raise
/// a banner. Anti-spam is the whole point — a band fires once on first crossing, no two escalations
/// land within `escalationCooldown`, and a band re-arms only after `escalationRearm` below its
/// threshold. Pure and value-typed (like `Metrics`), so it unit-tests without the physics; `Simulation`
/// feeds it live signals in E4b.
public struct EscalationTracker: Sendable {
    /// A raised escalation — which band, and when. The app turns this into a banner, haptic and sound.
    public struct Escalation: Sendable, Equatable {
        public let band: EscalationBand
        public let time: TimeInterval
    }

    /// The live signals the tracker reads each frame; `Simulation` fills these from its own state.
    public struct Signals: Sendable {
        public let peakDensity: Double
        public let exitBlocked: Bool
        public let casualties: Int
        public init(peakDensity: Double, exitBlocked: Bool, casualties: Int) {
            self.peakDensity = peakDensity
            self.exitBlocked = exitBlocked
            self.casualties = casualties
        }
    }

    private var armed: [EscalationBand: Bool]
    private var inactiveSince: [EscalationBand: TimeInterval]
    private var lastEscalationTime: TimeInterval?

    public init() {
        armed = Dictionary(uniqueKeysWithValues: EscalationBand.allCases.map { ($0, true) })
        inactiveSince = [:]
    }

    /// Fold one frame of live metrics; returns an escalation if a band fires now — at most one, the
    /// most severe pending band, since the cooldown serialises the rest.
    public mutating func update(time: TimeInterval, signals: Signals) -> Escalation? {
        // Refresh each band's active flag, and re-arm any that has stayed clear long enough.
        var active: [EscalationBand: Bool] = [:]
        for band in EscalationBand.allCases {
            let isActive = band.isActive(in: signals)
            active[band] = isActive
            if isActive {
                inactiveSince[band] = nil
            } else {
                let since = inactiveSince[band] ?? time
                inactiveSince[band] = since
                if armed[band] == false, time - since >= VerdictConstants.escalationRearm {
                    armed[band] = true
                }
            }
        }

        // No two escalations within the cooldown, whatever crossed.
        if let last = lastEscalationTime, time - last < VerdictConstants.escalationCooldown {
            return nil
        }

        // Fire the most severe band that is both active and armed.
        guard let winner = EscalationBand.allCases
            .filter({ active[$0] == true && armed[$0] == true })
            .max(by: { $0.severity < $1.severity })
        else { return nil }

        armed[winner] = false
        lastEscalationTime = time
        // A crossing into a higher density rung surpasses the lower ones — don't announce them later.
        if let rung = EscalationBand.densityLadder.firstIndex(of: winner) {
            for lower in EscalationBand.densityLadder.prefix(rung) where active[lower] == true {
                armed[lower] = false
            }
        }
        return Escalation(band: winner, time: time)
    }
}
