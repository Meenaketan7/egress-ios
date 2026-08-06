import EgressEngine
import SwiftUI

// MARK: - SimDensityBand

/// The live crowding band the HUD reads off peak density, mirroring the canvas density fills
/// (comfortable renders nothing; congestion → at-risk → crush climb the caution/danger ramp).
/// Carries its own label, tint and "rising" arrow so the status chip and density chip stay in sync.
enum SimDensityBand {
    case comfortable
    case congested
    case atRisk
    case crush

    /// Thresholds are the renderer's band edges (persons·m⁻²): 2 congested, 4 at-risk, 6 crush.
    init(density: Double) {
        switch density {
        case ..<2: self = .comfortable
        case ..<4: self = .congested
        case ..<6: self = .atRisk
        default: self = .crush
        }
    }

    /// Uppercase status word for the HUD chip.
    var status: String {
        switch self {
        case .comfortable: "COMFORTABLE"
        case .congested: "BUILDING"
        case .atRisk: "AT-RISK"
        case .crush: "CRUSH"
        }
    }

    var tint: Color {
        switch self {
        case .comfortable: .egVerdictPass
        case .congested: .egAccentGold
        case .atRisk: .egAccentTerracotta
        case .crush: .egAccentBrick
        }
    }

    /// A rising-danger arrow appears from at-risk up.
    var showsArrow: Bool {
        self == .atRisk || self == .crush
    }
}

// MARK: - SimHUDPill

/// The HUD pill that rides the top of the dark canvas (design hero): the wordmark and venue name, the
/// live agent count and run clock, the smoothed frame-rate, and the crowding status chip — all on the
/// dark-canvas surface so it reads over the game-screen.
struct SimHUDPill: View {
    let venueName: String
    let agents: Int
    let elapsed: Double
    let fps: Double
    let band: SimDensityBand

    var body: some View {
        VStack(alignment: .leading, spacing: EgressSpacing.xs) {
            HStack(spacing: EgressSpacing.sm) {
                Text("EGRESS")
                    .egData(.footnote, weight: .heavy)
                    .foregroundStyle(Color.egCanvasText)
                    .tracking(1)
                Text("|").foregroundStyle(Color.egCanvasSeparator)
                Text(venueName)
                    .egDisplay(.subheadline)
                    .foregroundStyle(Color.egCanvasText)
                    .lineLimit(1)
                Spacer(minLength: EgressSpacing.sm)
                Text("\(Int(fps.rounded())) FPS")
                    .egData(.caption2, weight: .semibold)
                    .foregroundStyle(fps >= 55 ? Color.egDataGreen : Color.egAccentGold)
            }
            HStack(spacing: EgressSpacing.md) {
                Label("\(agents) AGENTS", systemImage: AppSymbol.people.rawValue)
                    .egData(.caption2, weight: .semibold)
                    .foregroundStyle(Color.egCanvasText.opacity(0.85))
                Text(String(format: "t + %.1fs", elapsed))
                    .egData(.caption2)
                    .foregroundStyle(Color.egCanvasText.opacity(0.85))
                Spacer(minLength: EgressSpacing.sm)
                SimStatusChip(band: band)
            }
        }
        .padding(.horizontal, EgressSpacing.md)
        .padding(.vertical, EgressSpacing.sm)
        .egCanvasSurface()
    }
}

// MARK: - SimStatusChip

/// The small crowding-status capsule in the HUD (COMFORTABLE / BUILDING / AT-RISK / CRUSH). Tinted by
/// band, with the rising arrow from at-risk up so it never leans on colour alone (§5.6).
struct SimStatusChip: View {
    let band: SimDensityBand

    var body: some View {
        HStack(spacing: EgressSpacing.xxs) {
            if band.showsArrow {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 7, weight: .bold))
            }
            Text(band.status)
                .egData(.caption2, weight: .bold)
                .tracking(0.5)
        }
        .foregroundStyle(band.tint)
        .padding(.horizontal, EgressSpacing.sm)
        .padding(.vertical, EgressSpacing.xxs)
        .background(Capsule().fill(band.tint.opacity(0.18)))
        .overlay(Capsule().strokeBorder(band.tint.opacity(0.7), lineWidth: 1))
    }
}

// MARK: - SimDensityChip

/// The corner density read-out (design's `6.8 p/m² ▲`): a small swatch in the band colour, the peak
/// value, its unit, and the rising arrow. Sits at the bottom-trailing of the canvas.
struct SimDensityChip: View {
    let density: Double
    let band: SimDensityBand

    var body: some View {
        HStack(spacing: EgressSpacing.xs) {
            RoundedRectangle.egSquircle(3)
                .fill(band.tint)
                .frame(width: 12, height: 12)
            Text(String(format: "%.1f", density))
                .egData(.callout, weight: .bold)
                .foregroundStyle(Color.egCanvasText)
            Text("p/m²")
                .egData(.caption2)
                .foregroundStyle(Color.egCanvasText.opacity(0.7))
            if band.showsArrow {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(band.tint)
            }
        }
        .padding(.horizontal, EgressSpacing.sm)
        .padding(.vertical, EgressSpacing.xs)
        .egCanvasSurface(cornerRadius: EgressRadius.xs, tint: band.tint)
    }
}
