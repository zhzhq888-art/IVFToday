import SwiftUI

struct HistoryView: View {
    @Environment(ThemeController.self) private var themeController
    @Bindable var appState: AppState

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    private var sortedHistory: [ProtocolHistoryEntry] {
        appState.protocolHistory.sorted { $0.recordedAt > $1.recordedAt }
    }

    var body: some View {
        List {
            if sortedHistory.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    description: Text("Imported and applied protocol revisions will appear here.")
                )
            } else {
                ForEach(sortedHistory) { entry in
                    NavigationLink {
                        HistoryDetailView(entry: entry)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(historyTitle(for: entry))
                                        .font(.headline)
                                        .foregroundColor(theme.primary)
                                    Text(historySubtitle(for: entry))
                                        .font(.caption)
                                        .foregroundColor(theme.mutedText)
                                }

                                Spacer()

                                if criticalChangeCount(for: entry) > 0 {
                                    Text("\(criticalChangeCount(for: entry)) critical")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(theme.critical.opacity(0.12))
                                        .foregroundColor(theme.critical)
                                        .clipShape(Capsule())
                                }
                            }

                            if let changeSet = entry.changeSet, !changeSet.items.isEmpty {
                                Text("\(changeSet.items.count) changes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(theme.secondaryAccent)
                            } else {
                                Text("Baseline snapshot")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(theme.mutedText)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(theme.sectionBackground)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func historyTitle(for entry: ProtocolHistoryEntry) -> String {
        if let sourceFilename = entry.document.sourceFilename, !sourceFilename.isEmpty {
            return sourceFilename
        }
        return entry.document.sourceType.rawValue.capitalized + " Revision"
    }

    private func historySubtitle(for entry: ProtocolHistoryEntry) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, h:mm a"
        return "\(entry.document.sourceType.rawValue.capitalized) • \(formatter.string(from: entry.recordedAt))"
    }

    private func criticalChangeCount(for entry: ProtocolHistoryEntry) -> Int {
        entry.changeSet?.items.filter(\.isCritical).count ?? 0
    }
}

private struct HistoryDetailView: View {
    @Environment(ThemeController.self) private var themeController
    let entry: ProtocolHistoryEntry

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    var body: some View {
        List {
            Section("Document") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.document.sourceFilename ?? "Untitled Revision")
                        .font(.headline)
                    Text(entry.document.sourceType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(theme.mutedText)
                    Text(entry.document.normalizedText.isEmpty ? entry.document.rawText : entry.document.normalizedText)
                        .font(.caption)
                        .foregroundColor(theme.mutedText)
                        .lineLimit(8)
                }
                .padding(.vertical, 4)
                .listRowBackground(theme.sectionBackground)
            }

            Section("Changes") {
                if let changeSet = entry.changeSet, !changeSet.items.isEmpty {
                    ForEach(changeSet.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.subjectName)
                                .font(.subheadline.weight(.semibold))
                            Text(changeSummary(for: item))
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(theme.sectionBackground)
                    }
                } else {
                    Text("This entry is the baseline snapshot.")
                        .font(.caption)
                        .foregroundColor(theme.mutedText)
                        .listRowBackground(theme.sectionBackground)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Revision Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changeSummary(for item: ChangeItem) -> String {
        switch (item.oldValue, item.newValue) {
        case let (.some(oldValue), .some(newValue)):
            return "\(oldValue) -> \(newValue)"
        case let (.some(oldValue), nil):
            return "Before: \(oldValue)"
        case let (nil, .some(newValue)):
            return "Now: \(newValue)"
        case (nil, nil):
            return item.type.rawValue
        }
    }
}
