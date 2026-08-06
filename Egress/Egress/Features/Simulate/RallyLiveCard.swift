import EgressEngine
import SwiftUI

// MARK: - RallyRobot

/// RALLY's chassis (design §3, "RP-25") drawn as a chunky pixel robot to match the crowd's craft — a
/// tan head with a dark visor whose eyes take the current alert tint, plus an antenna. Pure vector
/// pixels, so it stays crisp at any size.
struct RallyRobot: View {
    /// Visor/antenna accent — the escalation band tint, so RALLY visibly "reacts" to the danger level.
    var accent: Color = .egAccentGold
    var side: CGFloat = 40

    /// 9×9 chassis: `#` shell, `V` dark visor, `E` glowing eye, `A` antenna.
    private static let rows = [
        "....A....",
        "....A....",
        "..#####..",
        ".#######.",
        ".#VVVVV#.",
        ".#VEVEV#.",
        ".#######.",
        ".##.#.##.",
        "..#...#..",
    ]

    var body: some View {
        Canvas { context, size in
            let cell = size.width / CGFloat(Self.rows[0].count)
            for (row, line) in Self.rows.enumerated() {
                for (col, ch) in line.enumerated() where ch != "." {
                    let rect = CGRect(
                        x: CGFloat(col) * cell,
                        y: CGFloat(row) * cell,
                        width: cell + 0.5,
                        height: cell + 0.5
                    )
                    let colour: Color = switch ch {
                    case "V": .egCanvasBase
                    case "E": accent
                    case "A": accent
                    default: .egRallyBody
                    }
                    context.fill(Path(rect), with: .color(colour))
                }
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

// MARK: - RallyLiveCard

/// RALLY's coaching card raised during a run, below the canvas: the robot, the "RALLY" mark, the live
/// band headline, and the coach's advice for the moment. It reacts to the current escalation and clears
/// with it. The grounded fix + Apply & re-run stay at the end-of-run results card, where the numbers are
/// final (§3.5) — this card coaches, it doesn't act.
struct RallyLiveCard: View {
    let escalation: EscalationTracker.Escalation

    private var tint: Color { escalation.band.tint }

    var body: some View {
        HStack(alignment: .top, spacing: EgressSpacing.md) {
            RallyRobot(accent: tint)

            VStack(alignment: .leading, spacing: EgressSpacing.xs) {
                HStack(spacing: EgressSpacing.sm) {
                    Text("RALLY").egMicroLabel()
                    Text(escalation.band.headline.uppercased())
                        .egData(.caption2, weight: .bold)
                        .foregroundStyle(tint)
                        .tracking(0.5)
                }
                Text(escalation.band.coaching)
                    .egBody(.footnote)
                    .foregroundStyle(Color.egTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(EgressSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle.egSquircle(EgressRadius.xl).fill(Color.egSurfaceRaised)
        )
        .overlay(
            RoundedRectangle.egSquircle(EgressRadius.xl).strokeBorder(tint.opacity(0.55), lineWidth: 1.5)
        )
        // One grouped element: VoiceOver reads "RALLY", the headline, then the coaching in order (§5.6).
        .accessibilityElement(children: .combine)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
