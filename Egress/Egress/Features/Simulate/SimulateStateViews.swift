import EgressEngine
import SwiftUI

// MARK: - SimulateEmptyState

//
// Every non-running state the Simulate flow can be in, resolved to a calm, explicit panel — never a
// frozen or ambiguous canvas. Each is deliberately reachable so it can be shown in the recording: the
// empty first-launch, the route-solve warm-up, a return-from-background pause, and the thermal /
// above-budget step-down notice. Offline and permission are stated, not simulated — the app asks for
// nothing and sends nothing, so there is no denial screen to fake.

/// Simulate tab, first launch: no venue chosen yet. A dimmed blueprint grid behind a plain statement of
/// the state and a single primary action — load the demo scenario — plus a pointer to the Spaces tab for
/// authored venues.
struct SimulateEmptyState: View {
    let onLoadDemo: () -> Void

    var body: some View {
        ZStack {
            BlueprintBackdrop()
            VStack(spacing: EgressSpacing.lg) {
                Image(systemName: "square.grid.3x3.square")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.egTextSecondary)
                VStack(spacing: EgressSpacing.xs) {
                    Text("NO SPACE LOADED")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(Color.egTextPrimary)
                    Text("Load a scenario to run an evacuation, or build your own in the Spaces tab.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.egTextSecondary)
                        .frame(maxWidth: 300)
                }
                Button(action: onLoadDemo) {
                    Label("Load demo scenario", systemImage: "play.fill")
                        .frame(maxWidth: 260)
                        .padding(.vertical, EgressSpacing.xs)
                }
                .buttonStyle(.borderedProminent)
                .tint(.egDataGreen)
            }
            .padding(EgressSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No space loaded. Load the demo scenario, or build your own in the Spaces tab.")
    }
}

// MARK: - SimulateLoadingState

/// Route-solve warm-up: shown while the navigation field is being built and the crowd spawned, so the
/// first frame is never a frozen canvas. Determinate — it reports real preparation progress.
struct SimulateLoadingState: View {
    /// 0…1 preparation progress.
    let progress: Double

    var body: some View {
        ZStack {
            BlueprintBackdrop()
            VStack(spacing: EgressSpacing.md) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.egDataGreen)
                    .frame(maxWidth: 220)
                Text("Solving evacuation routes…")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Color.egTextSecondary)
            }
            .padding(EgressSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Solving evacuation routes, \(Int(progress * 100)) percent")
    }
}

// MARK: - PausedOnReturnPanel

/// Returned from the background mid-run: the sim never auto-resumes (§E.2). A calm, centred panel states
/// the run is held and offers an explicit resume, so a run is never silently advanced while unseen.
struct PausedOnReturnPanel: View {
    let onResume: () -> Void

    var body: some View {
        VStack(spacing: EgressSpacing.md) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Color.egTextPrimary)
            Text("PAUSED")
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(Color.egTextPrimary)
            Text("The run was held when Egress went to the background. It won't resume on its own.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.egTextSecondary)
                .frame(maxWidth: 260)
            Button(action: onResume) {
                Label("Resume run", systemImage: "play.fill").padding(.horizontal, EgressSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(.egDataGreen)
        }
        .padding(EgressSpacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle.egSquircle(EgressRadius.lg))
        .padding(EgressSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Paused. The run was held when Egress went to the background and will not resume on its own.")
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - PerformanceNotice

/// A quiet, mono step-down line for the two performance-pressure states (§E.2 failure/recovery): the
/// device running hot, or the run carrying more agents than the validated budget. Informational, calm,
/// and always legible without colour.
struct PerformanceNotice: View {
    enum Kind: Equatable {
        case thermal(String)
        case aboveBudget(agents: Int, budget: Int)

        var line: String {
            switch self {
            case let .thermal(state): "THERMAL \(state.uppercased()) — capping detail to hold frame rate"
            case let .aboveBudget(agents, budget): "ABOVE BUDGET — \(agents) agents (validated \(budget))"
            }
        }
    }

    let kind: Kind

    var body: some View {
        HStack(spacing: EgressSpacing.xs) {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .font(.system(size: 11, weight: .semibold))
            Text(kind.line)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(Color.egVerdictWarn)
        .padding(.horizontal, EgressSpacing.sm)
        .padding(.vertical, EgressSpacing.xxs)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel(kind.line.replacingOccurrences(of: "—", with: ","))
    }
}

// MARK: - BlueprintBackdrop

/// A dimmed 0.25 m blueprint grid — the same visual language as the live canvas, so the empty and
/// loading states read as "the canvas, at rest" rather than a blank screen.
private struct BlueprintBackdrop: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 22
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(.egCanvasGridMajor.opacity(0.5)), lineWidth: 0.5)
        }
        .background(Color.egCanvasBase)
        .accessibilityHidden(true)
    }
}
