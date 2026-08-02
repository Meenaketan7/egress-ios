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
                .fontWeight(.semibold)
            Spacer(minLength: 0)
            Text(String(format: "%.0fs", escalation.time))
                .egData(.footnote)
                .foregroundStyle(Color.egTextSecondary)
        }
        .foregroundStyle(escalation.band.tint)
        .padding(.horizontal, EgressSpacing.lg)
        .padding(.vertical, EgressSpacing.md)
        .frame(maxWidth: .infinity)
        .egGlassSurface()
        .overlay(
            RoundedRectangle.egSquircle(EgressRadius.md)
                .strokeBorder(escalation.band.tint.opacity(0.7), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
