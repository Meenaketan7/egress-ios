import EgressEngine
import SwiftUI

// MARK: - SimTimeline

/// The run timeline (design's two-mode scrubber). It has different affordances depending on the run
/// state:
///  • **During the run** — a progress track of how much of the crowd is out, with no thumb (you can't
///    seek a live run), plus a tick at each escalation.
///  • **Paused or finished** — a seekable track over the recorded frames, with a draggable thumb, so
///    you can scrub back through what happened.
struct SimTimeline: View {
    /// 0…1 fill. Evacuated fraction while running; scrub position (frame index) when seekable.
    let progress: Double
    /// Sim-time of the frame currently shown, for the right-hand label.
    let elapsed: Double
    /// Escalation tick positions as 0…1 fractions of the run so far.
    let ticks: [Double]
    /// Band tint for the fill — the track warms as the crowd crowds.
    let tint: Color
    let seekable: Bool
    /// Called with a 0…1 fraction as the user scrubs (seekable mode only).
    let onScrub: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.egCanvasRaised)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, width * clamped))
                // Escalation ticks — small charcoal notches over the track.
                ForEach(Array(ticks.enumerated()), id: \.offset) { _, fraction in
                    Rectangle()
                        .fill(Color.egAccentTerracotta)
                        .frame(width: 2, height: 14)
                        .offset(x: width * min(max(fraction, 0), 1) - 1)
                }
                if seekable {
                    Circle()
                        .fill(Color.egCanvasText)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(Color.egCanvasBase, lineWidth: 2))
                        .offset(x: max(0, min(width - 16, width * clamped - 8)))
                }
            }
            .frame(height: 16)
            .contentShape(Rectangle())
            .gesture(
                seekable
                    ? DragGesture(minimumDistance: 0)
                    .onChanged { value in onScrub(min(max(value.location.x / width, 0), 1)) }
                    : nil
            )
        }
        .frame(height: 16)
        .padding(.horizontal, EgressSpacing.md)
        .padding(.vertical, EgressSpacing.sm)
        .overlay(alignment: .trailing) {
            Text(String(format: "t + %.1fs", elapsed))
                .egData(.caption2, weight: .semibold)
                .foregroundStyle(Color.egTextSecondary)
                .padding(.trailing, EgressSpacing.md)
                .offset(y: 16)
        }
    }
}

// MARK: - SimTransportBar

/// The five-control transport (design's playback row): restart · step-back · play/pause · step-forward
/// · recenter. Play/pause is the prominent primary; the rest are neutral icon buttons. Step-forward and
/// restart stay live after the run finishes so you can inspect the final frames; play disables at the end.
struct SimTransportBar: View {
    let isRunning: Bool
    let isComplete: Bool
    let canStepBack: Bool
    let isScrubbing: Bool
    let onRestart: () -> Void
    let onStepBack: () -> Void
    let onPlayPause: () -> Void
    let onStepForward: () -> Void
    let onRecenter: () -> Void

    var body: some View {
        HStack(spacing: EgressSpacing.md) {
            iconButton(.restart, "Restart", action: onRestart)
                .accessibilityHint("Restarts the same crowd from the beginning")

            iconButton(.stepBack, "Step back", action: onStepBack)
                .disabled(!canStepBack)

            Button(action: onPlayPause) {
                Image(app: isRunning ? .pause : .play)
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(.egDataGreen)
            .disabled(isComplete)
            .accessibilityLabel(isRunning ? "Pause" : "Play")
            .accessibilityHint(isRunning ? "Pauses the evacuation" : "Sounds the alarm and starts the evacuation")

            iconButton(.stepForward, "Step forward", action: onStepForward)
                .disabled(isComplete && !isScrubbing)

            iconButton(.recenter, "Return to live", action: onRecenter)
                .disabled(!isScrubbing)
        }
    }

    private func iconButton(_ symbol: AppSymbol, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(app: symbol)
                .font(.body)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.bordered)
        .tint(.egDataGreen)
        .accessibilityLabel(label)
    }
}
