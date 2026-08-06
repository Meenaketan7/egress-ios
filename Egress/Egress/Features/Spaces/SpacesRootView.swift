import EgressEngine
import SwiftData
import SwiftUI

// MARK: - SpacesRootView

/// The Spaces library (§3.6): a gallery of furnished presets to start from, then the saved-run
/// history — every resolved simulation persisted as a `RunRecord`, newest-first with its score and
/// verdict. A custom cream header carries the wordmark and the Settings gear; the ＋ (in the floating
/// tab bar) and each preset card both open the parametric editor. Presented without a nav bar — the big
/// header *is* the chrome — and it reserves room for the floating tab bar via the parent's safe-area inset.
struct SpacesRootView: View {
    /// Opens the editor seeded with a preset (a full-screen cover owned by `AppRoot`).
    let onOpenPreset: (VenuePreset) -> Void

    /// Only the last ten runs — the history stays a glanceable strip, not an ever-growing ledger.
    @Query private var runs: [RunRecord]
    /// The settings sheet, raised from the gear in the header.
    @State private var showSettings = false
    /// Flips true on first appearance to stagger the preset cards in.
    @State private var appeared = false

    init(onOpenPreset: @escaping (VenuePreset) -> Void) {
        self.onOpenPreset = onOpenPreset
        var descriptor = FetchDescriptor<RunRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 10 // cap the recent-runs list at the ten most recent
        _runs = Query(descriptor)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EgressSpacing.xl) {
                header

                presetSection

                runsSection
            }
            .padding(.horizontal, EgressSpacing.lg)
            .padding(.top, EgressSpacing.sm)
            .padding(.bottom, EgressSpacing.xl)
        }
        .background(Color.egGround)
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showSettings) { SettingsSheet() }
        .onAppear { appeared = true }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: EgressSpacing.xs) {
                Text("SPACES")
                    .font(.system(size: 36, weight: .black))
                    .tracking(1)
                    .foregroundStyle(Color.egTextPrimary)
                Text("Library of environments.")
                    .egBody(.subheadline)
                    .foregroundStyle(Color.egTextSecondary)
            }

            Spacer(minLength: EgressSpacing.md)

            Button { showSettings = true } label: {
                VStack(spacing: EgressSpacing.xxs) {
                    Image(app: .settings)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.egTextPrimary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.egSurfaceRaised))
                        .overlay(Circle().strokeBorder(Color.egOutline, lineWidth: 2))
                    Text("Settings").egMicroLabel()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.top, EgressSpacing.sm)
    }

    // MARK: Presets

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: EgressSpacing.md) {
            sectionHeader("Start from a preset")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: EgressSpacing.md) {
                    ForEach(Array(VenuePreset.catalog.enumerated()), id: \.element.id) { index, preset in
                        Button { onOpenPreset(preset) } label: {
                            PresetCard(preset: preset)
                        }
                        .buttonStyle(PressableCardStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : 24)
                        .animation(Motion.card.delay(Double(index) * 0.06), value: appeared)
                    }
                }
                .padding(.vertical, EgressSpacing.xs)
                .padding(.trailing, EgressSpacing.md) // let the last card breathe past the edge
            }
            // Let the carousel bleed to the screen edges while the rest of the page keeps its margin.
            .padding(.horizontal, -EgressSpacing.lg)
            .padding(.horizontal, EgressSpacing.lg)
        }
    }

    // MARK: Recent runs

    private var runsSection: some View {
        VStack(alignment: .leading, spacing: EgressSpacing.md) {
            sectionHeader("Recent runs")

            if runs.isEmpty {
                Text("Pick a preset or tap ＋, run an evacuation, and its result lands here.")
                    .egBody(.subheadline)
                    .foregroundStyle(Color.egTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EgressSpacing.lg)
                    .background(RoundedRectangle.egSquircle(EgressRadius.md).fill(Color.egSurfaceRaised))
            } else {
                // One borderless cream container; rows carry no outline, just a hairline between them.
                VStack(spacing: 0) {
                    ForEach(Array(runs.enumerated()), id: \.element.id) { index, run in
                        if index > 0 {
                            Rectangle()
                                .fill(Color.egSeparator)
                                .frame(height: 1)
                                .padding(.horizontal, EgressSpacing.lg)
                        }
                        RunRow(run: run)
                    }
                }
                .background(RoundedRectangle.egSquircle(EgressRadius.lg).fill(Color.egSurfaceRaised))
            }
        }
    }

    /// A prominent title-case section label — the gallery's shelf headings.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.title3, design: .serif, weight: .bold))
            .foregroundStyle(Color.egTextPrimary)
    }
}

// MARK: - PressableCardStyle

/// A springy press for the gallery cards — they dip and dim on touch, like pressing a physical button.
private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Motion.tap, value: configuration.isPressed)
    }
}

// MARK: - RunRow

/// One saved run as a borderless row inside the shared pixel container (design: the recent-run list). The
/// venue and three labelled metrics — type, clearance time, occupancy — sit left; the pixel-font score and a
/// pixel PASS/WARN/FAIL pill sit right, tinted by verdict.
private struct RunRow: View {
    let run: RunRecord

    private var level: VerdictLevel? { VerdictLevel(rawValue: run.verdictRaw) }
    private var tint: Color { level?.tint ?? Color.egTextPrimary }

    var body: some View {
        HStack(alignment: .center, spacing: EgressSpacing.md) {
            VStack(alignment: .leading, spacing: EgressSpacing.sm) {
                Text(run.venueName)
                    .font(.system(.headline, design: .serif, weight: .bold))
                    .foregroundStyle(Color.egTextPrimary)

                HStack(alignment: .top, spacing: EgressSpacing.md) {
                    stat("Type", (run.venueType?.displayName ?? run.venueTypeRaw).uppercased())
                    stat("Clear time", String(format: "%.0fS", run.clearanceTime))
                    stat("Count", "\(run.occupancy) PEOPLE")
                }
            }

            Spacer(minLength: EgressSpacing.sm)

            VStack(alignment: .trailing, spacing: EgressSpacing.sm) {
                PixelText(text: "\(run.score)", pixel: 3.0, color: tint)
                verdictPill
            }
        }
        .padding(EgressSpacing.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(run.venueName), \(level?.label ?? run.verdictRaw), score \(run.score). \(run.occupancy) people, cleared in \(Int(run.clearanceTime)) seconds.")
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).egMicroLabel()
            Text(value)
                .font(.system(.footnote, design: .rounded, weight: .bold))
                .foregroundStyle(Color.egTextPrimary)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var verdictPill: some View {
        PixelText(text: (level?.label ?? run.verdictRaw).uppercased(), pixel: 1.85, color: tint)
            .padding(.horizontal, EgressSpacing.sm)
            .padding(.vertical, 4)
            .overlay(
                PixelCornerRect(radius: 7, pixel: 2).strokeBorder(tint.opacity(0.75), lineWidth: 1.5)
            )
    }
}

#Preview {
    SpacesRootView(onOpenPreset: { _ in })
        .environment(\.dependencies, .preview())
}
