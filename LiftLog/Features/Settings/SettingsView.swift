import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var settings = UserSettingsManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Appearance Section
                Section {
                    Picker("Appearance", selection: $settings.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                
                // Units Section
                Section {
                    Picker("Weight Unit", selection: $settings.weightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                } header: {
                    Text("Units")
                } footer: {
                    Text("All weights will be displayed in your selected unit.")
                }
                
                // Rest Timer Section
                Section {
                    Picker("Default Rest Duration", selection: $settings.defaultRestDuration) {
                        Text("30 seconds").tag(TimeInterval(30))
                        Text("60 seconds").tag(TimeInterval(60))
                        Text("90 seconds").tag(TimeInterval(90))
                        Text("2 minutes").tag(TimeInterval(120))
                        Text("3 minutes").tag(TimeInterval(180))
                        Text("5 minutes").tag(TimeInterval(300))
                    }
                } header: {
                    Text("Rest Timer")
                } footer: {
                    Text("The rest timer will start with this duration after completing a set.")
                }
                
                // Notifications Section
                Section {
                    Toggle("Haptic Feedback", isOn: $settings.hapticFeedbackEnabled)
                    Toggle("Sound", isOn: $settings.soundEnabled)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Alerts when rest timer completes.")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
