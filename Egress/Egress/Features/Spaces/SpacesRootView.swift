import EgressEngine
import SwiftData
import SwiftUI

// MARK: - SpacesRootView

/// The Spaces library (§3.6): a gallery of furnished presets to start from, then the saved-run
/// history — every resolved simulation persisted as a `RunRecord`, newest-first with its score and
/// verdict. The "+" and each preset card both open the parametric editor.
struct SpacesRootView: View {
    @Query(sort: \RunRecord.date, order: .reverse) private var runs: [RunRecord]
    /// The preset the user tapped, by id — drives a value-based push. (A label-based `NavigationLink`
    /// inside a horizontal `ScrollView` nested in a `List` row doesn't fire; explicit navigation does.)
    @State private var openPresetID: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Start from a preset") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: EgressSpacing.md) {
                            ForEach(VenuePreset.catalog) { preset in
                                Button {
                                    openPresetID = preset.id
                                } label: {
                                    PresetCard(preset: preset)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, EgressSpacing.md)
                        .padding(.vertical, EgressSpacing.xs)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Recent runs") {
                    if runs.isEmpty {
                        Text("Pick a preset or tap ＋, run an evacuation, and its result lands here.")
                            .egMicroLabel()
                            .foregroundStyle(Color.egTextSecondary)
                    } else {
                        ForEach(runs) { run in
                            RunRecordRow(run: run)
                        }
                    }
                }
                .listRowBackground(Color.egSurfaceRaised)
            }
            .scrollContentBackground(.hidden)
            .background(Color.egGround)
            .navigationTitle("Spaces")
            .navigationDestination(item: $openPresetID) { id in
                if let preset = VenuePreset.catalog.first(where: { $0.id == id }) {
                    EditorRootView(preset: preset)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EditorRootView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

// MARK: - RunRecordRow

/// One saved run: venue, score, and verdict, with the timestamp.
private struct RunRecordRow: View {
    let run: RunRecord

    private var level: VerdictLevel? {
        VerdictLevel(rawValue: run.verdictRaw)
    }

    var body: some View {
        HStack(spacing: EgressSpacing.md) {
            VStack(alignment: .leading, spacing: EgressSpacing.xxs) {
                Text(run.venueName)
                    .egBody(.headline)
                    .foregroundStyle(Color.egTextPrimary)
                HStack(spacing: EgressSpacing.sm) {
                    Text(run.venueType?.displayName ?? run.venueTypeRaw)
                    Text("·")
                    Text(String(format: "%.0fs to clear", run.clearanceTime))
                    Text("·")
                    Text("\(run.occupancy) people")
                }
                .egMicroLabel()
            }

            Spacer(minLength: EgressSpacing.md)

            VStack(alignment: .trailing, spacing: EgressSpacing.xxs) {
                Text("\(run.score)")
                    .egData(.title3)
                    .foregroundStyle(level?.tint ?? Color.egTextPrimary)
                Text((level?.label ?? run.verdictRaw).uppercased())
                    .font(.system(.caption2, design: .monospaced, weight: .semibold))
                    .foregroundStyle(level?.tint ?? Color.egTextSecondary)
            }
        }
        .padding(.vertical, EgressSpacing.xs)
    }
}

#Preview { SpacesRootView() }
