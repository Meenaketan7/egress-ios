import SwiftUI

// MARK: - SettingsSheet

/// The app's one settings surface (§4.2): the audio and haptic controls (§3.6 / §5.5.4), a plain-language
/// note on how the Safety Score is built, and the safety-framing disclaimer that must ride along with any
/// verdict — "educational analysis, not certified engineering advice" (§D). Deliberately small: v3 keeps
/// the settings scope to what actually ships.
struct SettingsSheet: View {
    @Environment(FeedbackServices.self) private var feedback
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = feedback.settings
        NavigationStack {
            Form {
                Section {
                    Toggle("Sound effects", isOn: $settings.soundEnabled)
                        .accessibilityHint("Master switch for the alarm, escalation and verdict cues")
                    Toggle("Reduce audio intensity", isOn: $settings.reduceAudioIntensity)
                        .disabled(!settings.soundEnabled)
                        .accessibilityHint("Softens the cues by about six decibels")
                } header: {
                    Text("Sound")
                } footer: {
                    Text("Cues respect the silent switch and mix with your own audio. No safety event is ever signalled by sound alone.")
                }

                Section {
                    Toggle("Reduce haptic intensity", isOn: $settings.reduceHapticIntensity)
                        .accessibilityHint("Halves haptic strength and simplifies the crush pattern")
                } header: {
                    Text("Haptics")
                } footer: {
                    Text("Haptics play on device only, and only for events that concern the analyst — thresholds, casualties and verdicts.")
                }

                Section("How scoring works") {
                    Text("The Safety Score starts at 100 and deducts for casualties, dangerous density, the fraction of the crowd left at risk, and slow clearance. A run PASSES, gets a WARN, or FAILS on those same thresholds.")
                        .egBody(.callout)
                        .foregroundStyle(Color.egTextSecondary)
                }

                Section {
                    Text("Egress is an educational analysis tool, not certified engineering advice. Runs are simplified models — always defer to a qualified fire-safety professional and your local building code.")
                        .egBody(.footnote)
                        .foregroundStyle(Color.egTextSecondary)
                } header: {
                    Text("Disclaimer")
                } footer: {
                    Text("100% on-device. Nothing you simulate leaves this iPhone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
