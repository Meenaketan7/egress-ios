import EgressEngine
import SwiftUI

/// The parametric venue editor (§3.5). The user shapes a room, drops walls/exits/objects by dragging
/// on the canvas, dials the crowd, and — once the floor actually drains — pushes into the simulator
/// with the authored venue. This is what replaces the hard-coded `SampleVenue` in the core journey.
struct EditorRootView: View {
    @State private var model: EditorModel
    @State private var goToSimulate = false
    @Environment(FeedbackServices.self) private var feedback: FeedbackServices?
    private let navTitle: String

    /// A blank room the user shapes from scratch.
    init() {
        _model = State(initialValue: EditorModel())
        navTitle = "New Space"
    }

    /// A furnished preset the user can tweak, then run — the Spaces gallery entry point.
    init(preset: VenuePreset) {
        _model = State(initialValue: EditorModel(preset: preset))
        navTitle = preset.title
    }

    var body: some View {
        VStack(spacing: 0) {
            canvas
            controlPanel
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { simulateBar }
        .navigationDestination(isPresented: $goToSimulate) {
            SimulateScreen(venue: model.venue, config: model.config)
        }
    }

    // MARK: Canvas + tools

    private var canvas: some View {
        EditorCanvasView(model: model)
            .frame(maxWidth: .infinity, minHeight: 220, maxHeight: .infinity)
            .background(Color.egCanvasBase)
            .environment(\.colorScheme, .dark)
            .overlay(alignment: .bottom) {
                VStack(spacing: EgressSpacing.xs) {
                    toolPalette
                    Text(model.tool.hint)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.egTextSecondary)
                        .padding(.bottom, EgressSpacing.xs)
                }
                .padding(.horizontal, EgressSpacing.md)
            }
    }

    private var toolPalette: some View {
        HStack(spacing: EgressSpacing.xs) {
            ForEach(EditorTool.allCases) { tool in
                let selected = model.tool == tool
                Button {
                    model.tool = tool
                    feedback?.haptics.play(.toolTap)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tool.symbol).font(.system(size: 16, weight: .semibold))
                        Text(tool.label).font(.system(size: 10, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, EgressSpacing.sm)
                    .background(
                        RoundedRectangle.egSquircle(EgressRadius.xs)
                            .fill(selected ? tool.tint.opacity(0.22) : .clear)
                    )
                    .overlay(
                        RoundedRectangle.egSquircle(EgressRadius.xs)
                            .stroke(selected ? tool.tint : Color.egSeparator, lineWidth: selected ? 1.5 : 1)
                    )
                    .foregroundStyle(selected ? tool.tint : Color.egTextSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(tool.label) tool")
                .accessibilityHint(tool.hint)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(EgressSpacing.sm)
        .background(.ultraThinMaterial, in: RoundedRectangle.egSquircle(EgressRadius.md))
    }

    // MARK: Inspector

    private var controlPanel: some View {
        Form {
            Section("Venue") {
                TextField("Name", text: $model.name, prompt: Text(model.type.displayName))
                Picker("Type", selection: $model.type) {
                    ForEach(VenueType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section("Room") {
                Stepper(value: $model.widthMetres, in: EditorModel.minRoom ... EditorModel.maxRoom, step: 0.5) {
                    LabeledContent("Width", value: String(format: "%.1f m", model.widthMetres))
                }
                .onChange(of: model.widthMetres) { _, _ in model.clampToBounds() }
                Stepper(value: $model.heightMetres, in: EditorModel.minRoom ... EditorModel.maxRoom, step: 0.5) {
                    LabeledContent("Depth", value: String(format: "%.1f m", model.heightMetres))
                }
                .onChange(of: model.heightMetres) { _, _ in model.clampToBounds() }
                LabeledContent("Floor area", value: String(format: "%.0f m²", model.venue.netFloorArea))
            }

            Section("Crowd") {
                VStack(alignment: .leading, spacing: EgressSpacing.xs) {
                    HStack {
                        Text("\(model.crowd) people").egData(.body)
                        Spacer()
                        Text(model.crowdLoadLabel)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .padding(.horizontal, EgressSpacing.sm)
                            .padding(.vertical, 2)
                            .background(model.crowdLoadTint.opacity(0.18), in: Capsule())
                            .foregroundStyle(model.crowdLoadTint)
                    }
                    Slider(
                        value: Binding(get: { Double(model.crowd) }, set: { model.crowd = Int($0) }),
                        in: Double(EditorModel.minCrowd) ... Double(EditorModel.maxCrowd), step: 1
                    )
                    .tint(.egDataGreen)
                    Text(String(format: "%.1f people/m² average loading", model.crowdDensity))
                        .egMicroLabel()
                }
            }

            Section("Layout") {
                LabeledContent("Walls", value: "\(model.walls.count)")
                LabeledContent("Exits", value: "\(model.exits.count)")
                LabeledContent("Objects", value: "\(model.obstacles.count)")
                Button(role: .destructive) {
                    model.clearElements()
                    feedback?.haptics.play(.deleteConfirmed)
                } label: {
                    Label("Clear layout", systemImage: "trash")
                }
                .disabled(model.walls.isEmpty && model.exits.isEmpty && model.obstacles.isEmpty)
            }
        }
        .frame(maxHeight: 320)
    }

    // MARK: Simulate hand-off

    private var simulateBar: some View {
        VStack(spacing: EgressSpacing.xs) {
            if let issue = model.blockingIssue {
                Label(issue, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.egVerdictWarn)
                    .multilineTextAlignment(.center)
            }
            Button {
                goToSimulate = true
            } label: {
                Label("Run Simulation", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, EgressSpacing.xs)
            }
            .buttonStyle(.borderedProminent)
            .tint(.egDataGreen)
            .disabled(!model.isSimulable)
        }
        .padding(EgressSpacing.md)
        .background(.bar)
    }
}

#Preview {
    NavigationStack { EditorRootView() }
}
