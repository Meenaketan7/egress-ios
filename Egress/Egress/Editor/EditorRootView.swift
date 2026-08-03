import EgressEngine
import SwiftUI

/// The parametric venue editor (§3.5). The user shapes a room, drops walls/exits/objects by dragging
/// on the canvas, dials the crowd, and — once the floor actually drains — pushes into the simulator
/// with the authored venue. This is what replaces the hard-coded `SampleVenue` in the core journey.
struct EditorRootView: View {
    @State private var model: EditorModel
    @State private var goToSimulate = false
    @Environment(FeedbackServices.self)
    private var feedback: FeedbackServices?
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

            Section {
                Stepper(value: $model.widthMetres, in: EditorModel.minRoom ... EditorModel.maxRoom, step: 0.5) {
                    LabeledContent("Width", value: String(format: "%.1f m", model.widthMetres))
                }
                .onChange(of: model.widthMetres) { _, _ in model.clampToBounds() }
                Stepper(value: $model.heightMetres, in: EditorModel.minRoom ... EditorModel.maxRoom, step: 0.5) {
                    LabeledContent("Depth", value: String(format: "%.1f m", model.heightMetres))
                }
                .onChange(of: model.heightMetres) { _, _ in model.clampToBounds() }
                LabeledContent("Floor area", value: String(format: "%.0f m²", model.venue.netFloorArea))
            } header: {
                Text("Room")
            } footer: {
                Text("Each grid square is 0.25 m — four squares make a metre. Every wall, door and object snaps to it.")
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
                        in: Double(EditorModel.minCrowd) ... Double(EditorModel.maxCrowd),
                        step: 1
                    )
                    .tint(.egDataGreen)
                    Text(String(format: "%.1f people/m² average loading", model.crowdDensity))
                        .egMicroLabel()
                }
            }

            exitsSection
            objectsSection

            Section("Layout") {
                LabeledContent("Walls", value: "\(model.walls.count)")
                Button(role: .destructive) {
                    model.clearElements()
                    feedback?.haptics.play(.deleteConfirmed)
                } label: {
                    Label("Clear layout", systemImage: "trash")
                }
                .disabled(model.walls.isEmpty && model.exits.isEmpty && model.obstacles.isEmpty)
            }
        }
        .frame(maxHeight: 340)
    }

    /// Exits as an accessible list (§5.6): each doorway gets a clear-width stepper (0.1 m steps) and a
    /// remove button, and a menu adds a new doorway centred on any wall — so authoring never requires a
    /// drag. Widths below the citable 1.2 m exit minimum flag themselves.
    private var exitsSection: some View {
        Section {
            ForEach(model.exits) { exit in
                VStack(alignment: .leading, spacing: EgressSpacing.xs) {
                    Stepper(
                        value: Binding(
                            get: { model.exitWidth(exit.id) },
                            set: { model.setExitWidth(exit.id, to: $0) }
                        ),
                        in: EditorModel.minEditableExit ... max(EditorModel.minEditableExit, model.maxExitWidth(exit.id)),
                        step: EditorModel.exitStep
                    ) {
                        LabeledContent("Exit \(exit.id)", value: String(format: "%.1f m", model.exitWidth(exit.id)))
                    }
                    .accessibilityHint("Adjusts the clear width of exit \(exit.id) in tenths of a metre")
                    if model.exitWidth(exit.id) + 0.001 < SafetyStandards.minExitWidth {
                        Label("Below the 1.2 m exit minimum", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.egVerdictWarn)
                    }
                    Button(role: .destructive) {
                        model.removeExit(exit.id)
                        feedback?.haptics.play(.deleteConfirmed)
                    } label: {
                        Label("Remove", systemImage: "minus.circle").font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Remove exit \(exit.id)")
                }
                .padding(.vertical, 2)
            }
            Menu {
                ForEach(EditorModel.RoomEdge.allCases) { edge in
                    Button(edge.label) {
                        model.addExit(on: edge)
                        feedback?.haptics.play(.toolTap)
                    }
                }
            } label: {
                Label("Add exit on a wall", systemImage: "plus.rectangle.on.rectangle")
            }
            .accessibilityHint("Adds a doorway centred on the wall you choose")
        } header: {
            Text("Exits (\(model.exits.count))")
        } footer: {
            if model.exits.isEmpty {
                Text("Add at least one exit so the crowd can escape.")
            }
        }
    }

    /// Objects as an accessible list (§5.6): relocatable furniture gets nudge controls and a remove
    /// button; structural elements show a disabled `LOCKED — STRUCTURAL` row — routes plan around them
    /// and they never move (V5).
    private var objectsSection: some View {
        Section {
            if model.obstacles.isEmpty {
                Text("No objects placed.")
                    .font(.callout)
                    .foregroundStyle(Color.egTextSecondary)
            }
            ForEach(model.obstacles) { object in
                if object.isRelocatable {
                    VStack(alignment: .leading, spacing: EgressSpacing.xs) {
                        LabeledContent("Object \(object.id)", value: String(format: "%.1f × %.1f m", object.size.x, object.size.y))
                        HStack(spacing: EgressSpacing.md) {
                            nudge(object.id, "arrow.left", "left", Vec2(-0.5, 0))
                            nudge(object.id, "arrow.right", "right", Vec2(0.5, 0))
                            nudge(object.id, "arrow.up", "up", Vec2(0, -0.5))
                            nudge(object.id, "arrow.down", "down", Vec2(0, 0.5))
                            Spacer()
                            Button(role: .destructive) {
                                model.removeObstacle(object.id)
                                feedback?.haptics.play(.deleteConfirmed)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .accessibilityLabel("Remove object \(object.id)")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 2)
                } else {
                    LabeledContent {
                        Text("LOCKED — STRUCTURAL")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.egTextSecondary)
                    } label: {
                        Label("Object \(object.id)", systemImage: "lock.fill")
                    }
                    .accessibilityHint("Structural element — evacuation routes are planned around it and it cannot be moved")
                }
            }
        } header: {
            Text("Objects (\(model.obstacles.count))")
        }
    }

    /// One obstacle-nudge button — moves a relocatable object half a metre in `delta`'s direction.
    private func nudge(_ id: Int, _ symbol: String, _ direction: String, _ delta: Vec2) -> some View {
        Button {
            model.nudgeObstacle(id, by: delta)
            feedback?.haptics.play(.toolTap)
        } label: {
            Image(systemName: symbol)
        }
        .accessibilityLabel("Move object \(id) \(direction) by half a metre")
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
