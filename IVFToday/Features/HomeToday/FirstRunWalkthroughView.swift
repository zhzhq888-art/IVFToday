import SwiftUI

struct FirstRunWalkthroughView: View {
    @Environment(ThemeController.self) private var themeController
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    private var theme: AppTheme.Palette { themeController.palette }

    var body: some View {
        NavigationStack {
            List {
                Section("Welcome to IVFToday") {
                    Text("A local-first checklist to reduce execution stress during IVF treatment.")
                        .font(.subheadline)
                        .foregroundColor(theme.mutedText)
                    featureRow(icon: "sun.max.fill", title: "Today", subtitle: "See medications and appointments for today.")
                    featureRow(icon: "arrow.triangle.2.circlepath", title: "Changes", subtitle: "Review what changed since the last protocol.")
                    featureRow(icon: "shippingbox.fill", title: "Inventory", subtitle: "Track days-left and low-stock warnings.")
                }
                .listRowBackground(theme.sectionBackground)

                Section("Safety") {
                    SafetyNoticeCard(
                        title: "Support tool, not medical advice",
                        message: "Always follow your clinic's direct instructions. If there is any mismatch, call your clinic immediately.",
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
                    Button("Get Started") {
                        onComplete()
                        dismiss()
                    }
                }
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(theme.primary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
