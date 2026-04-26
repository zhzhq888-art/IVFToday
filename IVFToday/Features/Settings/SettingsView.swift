import SwiftUI

struct SettingsView: View {
    @Environment(ThemeController.self) private var themeController
    @AppStorage(OnboardingPreferences.hasSeenWalkthroughKey) private var hasSeenFirstRunWalkthrough = false
    @Bindable var appState: AppState
    @State private var viewModel = SettingsViewModel()
    @State private var isShowingOnboarding = false
    @State private var isShowingResetConfirmation = false

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    var body: some View {
        List {
            Section("Notifications") {
                Toggle(isOn: Binding(
                    get: { appState.inventoryNotificationsEnabled },
                    set: { appState.setInventoryNotificationsEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.notificationTitle)
                            .font(.headline)
                        Text(viewModel.notificationSubtitle)
                            .font(.caption)
                            .foregroundColor(theme.mutedText)
                    }
                }
                .tint(theme.primary)
                .listRowBackground(theme.sectionBackground)
            }

            Section("Onboarding") {
                Button {
                    hasSeenFirstRunWalkthrough = false
                    isShowingOnboarding = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.onboardingTitle)
                            .font(.headline)
                        Text(viewModel.onboardingSubtitle)
                            .font(.caption)
                            .foregroundColor(theme.mutedText)
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(theme.sectionBackground)
            }

            Section("Appearance") {
                Picker("Theme Preset", selection: Binding(
                    get: { themeController.selectedPreset },
                    set: { themeController.selectedPreset = $0 }
                )) {
                    ForEach(AppTheme.Preset.allCases) { preset in
                        Text(preset.title)
                            .tag(preset)
                    }
                }
                .listRowBackground(theme.sectionBackground)
            }

            Section("Data") {
                Button(role: .destructive) {
                    isShowingResetConfirmation = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.resetTitle)
                            .font(.headline)
                        Text(viewModel.resetSubtitle)
                            .font(.caption)
                            .foregroundColor(theme.mutedText)
                    }
                }
                .listRowBackground(theme.sectionBackground)
            }

            Section("Safety & Privacy") {
                Text(viewModel.safetyDisclaimer)
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
                    .listRowBackground(theme.sectionBackground)
                Text(viewModel.privacyStatement)
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
                    .listRowBackground(theme.sectionBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView {
                hasSeenFirstRunWalkthrough = true
            }
            .environment(themeController)
        }
        .alert(
            viewModel.resetConfirmationTitle,
            isPresented: $isShowingResetConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                appState.resetToDemoData()
                hasSeenFirstRunWalkthrough = false
            }
        } message: {
            Text(viewModel.resetConfirmationMessage)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(appState: DemoDataFactory.createAppState())
            .environment(ThemeController())
    }
}
