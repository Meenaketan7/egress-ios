import EgressEngine
import SwiftUI

// MARK: - Escalation presentation

extension EscalationBand {
    /// The banner headline for each live band (§3.3).
    var headline: String {
        switch self {
        case .congestion: "Congestion building"
        case .bottleneck: "Bottleneck at the exit"
        case .crush: "Crush density reached"
        case .exitBlocked: "An exit is blocked by fire"
        case .casualty: "Casualty reported"
        }
    }

    /// Amber for the approach bands, red once it is dangerous — reusing the verdict ramp.
    var tint: Color {
        switch self {
        case .congestion, .bottleneck: .egVerdictWarn
        case .crush, .exitBlocked, .casualty: .egVerdictFail
        }
    }

    var symbol: String {
        switch self {
        case .congestion, .bottleneck: "exclamationmark.triangle.fill"
        case .crush: "person.3.sequence.fill"
        case .exitBlocked: "flame.fill"
        case .casualty: "cross.case.fill"
        }
    }

    /// Ink that reads on the solid band: charcoal on the bright amber approach bands, cream on the
    /// darker red danger bands.
    var ink: Color {
        switch self {
        case .congestion, .bottleneck: .egCanvasBase
        case .crush, .exitBlocked, .casualty: .egCanvasText
        }
    }

    /// RALLY's live coaching line for this band — the coach's *voice* on the alert, distinct from the
    /// banner's flat statement of fact. No fabricated figures: it explains and advises, the grounded
    /// numbers land at the verdict (§3.5).
    var coaching: String {
        switch self {
        case .congestion:
            "The crowd is packing in. Keep everyone moving toward the nearest exit."
        case .bottleneck:
            "The exit can't keep up with the flow — this is exactly where a crush begins."
        case .crush:
            "Dangerous density. In a real venue you'd hold the crowd back and meter the doors now."
        case .exitBlocked:
            "Fire has cut off a route. The exits still open have to carry everyone out."
        case .casualty:
            "Someone is down in the crush. Clear, unblocked egress matters most right now."
        }
    }
}

// MARK: - EscalationBanner

/// The amber/red banner RALLY raises *during* a run when the crowd crosses a live safety band (§3.3),
/// distinct from the end-of-run verdict. Shown over the top of the canvas; the controller clears it a
/// few seconds after each crossing, so it announces and fades rather than pinning.
struct EscalationBanner: View {
    let escalation: EscalationTracker.Escalation

    var body: some View {
        HStack(spacing: EgressSpacing.sm) {
            Image(systemName: escalation.band.symbol)
            Text(escalation.band.headline)
                .egBody(.callout)
                .fontWeight(.bold)
            Spacer(minLength: 0)
            Text(String(format: "t + %.0fs", escalation.time))
                .egData(.footnote, weight: .semibold)
                .opacity(0.75)
        }
        .foregroundStyle(escalation.band.ink)
        .padding(.horizontal, EgressSpacing.lg)
        .padding(.vertical, EgressSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle.egSquircle(EgressRadius.md).fill(escalation.band.tint)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
