import SwiftUI

struct ChangeReviewView: View {
    @Environment(ThemeController.self) private var themeController
    let changeItems: [ChangeItem]

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    var body: some View {
        List {
            if changeItems.isEmpty {
                ContentUnavailableView(
                    "No Changes Detected",
                    systemImage: "checkmark.circle",
                    description: Text("Today's protocol matches the previous instructions.")
                )
            } else {
                if !criticalItems.isEmpty {
                    Section("Critical") {
                        ForEach(criticalItems) { item in
                            changeRow(for: item)
                        }
                    }
                }

                if !medicationItems.isEmpty {
                    Section("Medication Changes") {
                        ForEach(medicationItems) { item in
                            changeRow(for: item)
                        }
                    }
                }

                if !appointmentItems.isEmpty {
                    Section("Appointment Changes") {
                        ForEach(appointmentItems) { item in
                            changeRow(for: item)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Changes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var criticalItems: [ChangeItem] {
        changeItems.filter(\.isCritical)
    }

    private var medicationItems: [ChangeItem] {
        changeItems.filter { !$0.isCritical && $0.subjectType == .medication }
    }

    private var appointmentItems: [ChangeItem] {
        changeItems.filter { !$0.isCritical && $0.subjectType == .appointment }
    }

    private func title(for type: ChangeType) -> String {
        switch type {
        case .added:
            return "New today"
        case .doseChanged:
            return "Dose changed"
        case .timeChanged:
            return "Time changed"
        case .detailsChanged:
            return "Details changed"
        case .stopped:
            return "Stopped"
        }
    }

    @ViewBuilder
    private func changeRow(for item: ChangeItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(item.subjectName, systemImage: icon(for: item))
                    .font(.headline)

                Spacer()

                Text(badgeTitle(for: item.subjectType))
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.primary.opacity(0.08))
                    .foregroundColor(theme.primary)
                    .clipShape(Capsule())

                if item.isCritical {
                    Text("Critical")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.critical.opacity(0.14))
                        .foregroundColor(theme.critical)
                        .clipShape(Capsule())
                }
            }

            Text(title(for: item.type))
                .font(.subheadline.weight(.medium))
                .foregroundColor(color(for: item.type))

            if let oldValue = item.oldValue {
                Text("Before: \(oldValue)")
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
            }

            if let newValue = item.newValue {
                Text("Now: \(newValue)")
                    .font(.caption)
                    .foregroundColor(theme.primary)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(theme.sectionBackground)
    }

    private func icon(for item: ChangeItem) -> String {
        switch (item.subjectType, item.type) {
        case (.appointment, .added):
            return "calendar.badge.plus"
        case (.appointment, .timeChanged):
            return "calendar.badge.clock"
        case (.appointment, .detailsChanged):
            return "calendar.badge.exclamationmark"
        case (.appointment, .stopped):
            return "calendar.badge.minus"
        case (.appointment, .doseChanged):
            return "calendar"
        case (.medication, .added):
            return "plus.circle"
        case (.medication, .doseChanged):
            return "arrow.up.arrow.down.circle"
        case (.medication, .timeChanged):
            return "clock.badge.exclamationmark"
        case (.medication, .detailsChanged):
            return "text.badge.star"
        case (.medication, .stopped):
            return "minus.circle"
        }
    }

    private func badgeTitle(for subjectType: ChangeSubjectType) -> String {
        switch subjectType {
        case .medication:
            return "Medication"
        case .appointment:
            return "Appointment"
        }
    }

    private func color(for type: ChangeType) -> Color {
        switch type {
        case .added:
            return theme.success
        case .doseChanged:
            return theme.caution
        case .timeChanged:
            return theme.info
        case .detailsChanged:
            return theme.secondaryAccent
        case .stopped:
            return theme.critical
        }
    }
}
