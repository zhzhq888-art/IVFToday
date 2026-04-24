import SwiftUI

struct InventoryView: View {
    @Environment(ThemeController.self) private var themeController
    @Bindable var appState: AppState

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    private var inventoryItemsSnapshot: [InventoryItem] {
        appState.inventoryItems
    }

    var body: some View {
        List {
            Section("Low-Stock Notifications") {
                Toggle(isOn: Binding(
                    get: { appState.inventoryNotificationsEnabled },
                    set: { appState.setInventoryNotificationsEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable local reminders")
                            .font(.headline)
                        Text("When stock is low, schedule local alerts on this device.")
                            .font(.caption)
                            .foregroundColor(theme.mutedText)
                    }
                }
                .tint(theme.primary)
                .listRowBackground(theme.sectionBackground)
            }

            if !appState.inventoryAlerts.isEmpty {
                Section("Alerts") {
                    Text("Warning: one or more medications may run low soon.")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.caution)
                        .accessibilityIdentifier("inventory.alert.banner")
                        .listRowBackground(theme.sectionBackground)
                    ForEach(appState.inventoryAlerts) { alert in
                        let alertIdentifier = uiIdentifierSlug(alert.medicationName)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alert.medicationName)
                                .font(.headline)
                            Text(alert.message)
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                            if let daysLeft = alert.daysLeft {
                                Text("Estimated days left: \(formattedDaysLeft(daysLeft))")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(alert.isCritical ? theme.critical : theme.caution)
                            }
                        }
                        .accessibilityIdentifier("inventory.alert.row.\(alertIdentifier)")
                        .foregroundColor(alert.isCritical ? theme.critical : theme.caution)
                        .listRowBackground(theme.sectionBackground)
                    }
                }
            }

            Section("On Hand") {
                if inventoryItemsSnapshot.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No inventory items yet")
                            .font(.subheadline.weight(.semibold))
                        Text("Import or edit medications first. Active medications will appear here for stock tracking.")
                            .font(.caption)
                            .foregroundColor(theme.mutedText)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(theme.sectionBackground)
                } else {
                    ForEach(inventoryItemsSnapshot, id: \InventoryItem.id) { (item: InventoryItem) in
                        let projection = appState.inventoryProjection(for: item.id)
                        InventoryItemEditorRow(
                            item: item,
                            projection: projection,
                            theme: theme
                        ) { id, remainingAmount, alertThreshold in
                            appState.updateInventoryItem(
                                id: id,
                                remainingAmount: remainingAmount,
                                alertThreshold: alertThreshold
                            )
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(theme.sectionBackground)
                    }
                }
            }

            Section("Safety") {
                SafetyNoticeCard(
                    title: "Inventory alerts are reminders only",
                    message: "If low-stock is shown, confirm with your clinic and pharmacy immediately. Do not delay critical doses.",
                    theme: theme
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(theme.background)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDaysLeft(_ days: Double) -> String {
        if days < 1 {
            return "< 1 day"
        }
        return String(format: "%.1f days", days)
    }
}

private struct InventoryItemEditorRow: View {
    let item: InventoryItem
    let projection: InventoryProjection?
    let theme: AppTheme.Palette
    let onSave: (UUID, Double, Double) -> Void

    @State private var remainingDraft: String
    @State private var alertThresholdDraft: String

    private var identifierSlug: String {
        uiIdentifierSlug(item.medicationName)
    }

    init(
        item: InventoryItem,
        projection: InventoryProjection?,
        theme: AppTheme.Palette,
        onSave: @escaping (UUID, Double, Double) -> Void
    ) {
        self.item = item
        self.projection = projection
        self.theme = theme
        self.onSave = onSave
        _remainingDraft = State(initialValue: Self.formattedValue(item.remainingAmount))
        _alertThresholdDraft = State(initialValue: Self.formattedValue(item.alertThreshold))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.medicationName)
                    .font(.headline)
                Spacer()
                Text(item.remainingLabel)
                    .font(.subheadline)
                    .foregroundColor(theme.mutedText)
            }

            if let projection {
                HStack {
                    Text("Estimated days left")
                        .font(.caption)
                        .foregroundColor(theme.mutedText)
                    Spacer()
                    Text(daysLeftText(projection.daysLeft))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(projection.isCritical ? theme.critical : (projection.isLowStock ? theme.caution : theme.success))
                }
            }

            HStack {
                Text("Remaining")
                    .font(.caption)
                    .foregroundColor(theme.mutedText)

                Spacer()

                TextField("0", text: $remainingDraft)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 84)
                    .accessibilityIdentifier("inventory.remaining.\(identifierSlug)")

                Text(item.unit.rawValue)
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
            }

            HStack {
                Text("Alert threshold")
                    .font(.caption)
                    .foregroundColor(theme.mutedText)

                Spacer()

                TextField("0", text: $alertThresholdDraft)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 84)
                    .accessibilityIdentifier("inventory.threshold.\(identifierSlug)")

                Text(item.unit.rawValue)
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
            }

            HStack {
                Text("Updated \(item.lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(theme.mutedText)

                Spacer()

                Button("Save") {
                    guard let parsedRemainingAmount = parsedDouble(from: remainingDraft),
                          let parsedAlertThreshold = parsedDouble(from: alertThresholdDraft) else {
                        return
                    }

                    onSave(item.id, parsedRemainingAmount, parsedAlertThreshold)
                    remainingDraft = Self.formattedValue(max(0, parsedRemainingAmount))
                    alertThresholdDraft = Self.formattedValue(max(0, parsedAlertThreshold))
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.primary)
                .accessibilityIdentifier("inventory.save.\(identifierSlug)")
                .disabled(!canSave)
            }
        }
        .onChange(of: item) { _, newItem in
            remainingDraft = Self.formattedValue(newItem.remainingAmount)
            alertThresholdDraft = Self.formattedValue(newItem.alertThreshold)
        }
    }

    private var canSave: Bool {
        guard let parsedRemainingAmount = parsedDouble(from: remainingDraft),
              let parsedAlertThreshold = parsedDouble(from: alertThresholdDraft) else {
            return false
        }

        let normalizedRemaining = Self.formattedValue(max(0, parsedRemainingAmount))
        let normalizedThreshold = Self.formattedValue(max(0, parsedAlertThreshold))

        return normalizedRemaining != Self.formattedValue(item.remainingAmount)
            || normalizedThreshold != Self.formattedValue(item.alertThreshold)
    }

    private func parsedDouble(from value: String) -> Double? {
        Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func formattedValue(_ value: Double) -> String {
        value.formatted()
    }

    private func daysLeftText(_ days: Double?) -> String {
        guard let days else {
            return "N/A"
        }
        if days < 1 {
            return "< 1 day"
        }
        return String(format: "%.1f days", days)
    }
}

private func uiIdentifierSlug(_ value: String) -> String {
    let slug = value
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
    return slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
}
