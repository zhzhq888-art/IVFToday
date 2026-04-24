import SwiftUI

struct OnboardingView: View {
    @Environment(ThemeController.self) private var themeController
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    private var theme: AppTheme.Palette { themeController.palette }

    var body: some View {
        NavigationStack {
            List {
                Section("Welcome") {
                    Text(viewModel.headline)
                        .font(.title3.weight(.bold))
                    Text(viewModel.subheadline)
                        .font(.subheadline)
                        .foregroundColor(theme.mutedText)
                }
                .listRowBackground(theme.sectionBackground)

                Section("What You Can Do") {
                    ForEach(viewModel.featureItems) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.icon)
                                .foregroundColor(theme.primary)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundColor(theme.mutedText)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(theme.sectionBackground)
                }

                Section("Safety") {
                    SafetyNoticeCard(
                        title: viewModel.safetyTitle,
                        message: viewModel.safetyMessage,
                        theme: theme
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(theme.background)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Quick Walkthrough")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.primaryActionTitle) {
                        onComplete()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environment(ThemeController())
}
