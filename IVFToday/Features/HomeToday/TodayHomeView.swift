import SwiftUI

struct TodayHomeView: View {
    @Environment(ThemeController.self) private var themeController
    @AppStorage(OnboardingPreferences.hasSeenWalkthroughKey) private var hasSeenFirstRunWalkthrough = false
    @Bindable var appState: AppState
    @State private var pendingHighRiskTask: TodayTask?
    @State private var doubleConfirmTask: TodayTask?
    @State private var isShowingWalkthrough = false
    private let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing-enable-hooks")

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    var body: some View {
        TabView {
            NavigationStack {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appState.treatmentCase.title)
                                .font(.title2.weight(.bold))

                            Text("Current stage: \(appState.treatmentCase.stage.rawValue.capitalized)")
                                .font(.subheadline)
                                .foregroundColor(theme.mutedText)

                            if let clinicName = appState.treatmentCase.clinicName {
                                Label(clinicName, systemImage: "cross.case")
                                    .font(.caption)
                                    .foregroundColor(theme.mutedText)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(theme.sectionBackground)
                    }

                    Section("Safety") {
                        SafetyNoticeCard(
                            title: "Clinic instructions always win",
                            message: "Use this app to organize tasks, but if anything differs from your clinic instructions, follow the clinic and call them.",
                            theme: theme
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(theme.background)
                    }

                    if !appState.inventoryAlerts.isEmpty {
                        Section("Inventory Alerts") {
                            ForEach(appState.inventoryAlerts) { alert in
                                VStack(alignment: .leading, spacing: 6) {
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
                                .foregroundColor(alert.isCritical ? theme.critical : theme.caution)
                                .listRowBackground(theme.sectionBackground)
                            }
                        }
                    }

                    Section("Today's Actions") {
                        if appState.todayTasks.isEmpty {
                            emptyStateRow(
                                icon: "list.bullet.clipboard",
                                title: "No tasks for today yet",
                                subtitle: "Import instructions or add protocol details in Edit to generate today's task list."
                            )
                        } else {
                            ForEach(appState.todayTasks) { task in
                                let isCompleted = appState.isTaskCompleted(task.id)
                                let taskIdentifier = identifierSlug(for: task.title)
                                let completionIdentifier = task.riskLevel == .high
                                    ? "today.task.complete.high-risk.\(taskIdentifier)"
                                    : "today.task.complete.\(taskIdentifier)"
                                HStack(alignment: .top, spacing: 12) {
                                    Button {
                                        handleCompletionTap(task, isCompleted: isCompleted)
                                    } label: {
                                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isCompleted ? theme.success : theme.mutedText)
                                            .font(.system(size: 20, weight: .semibold))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier(completionIdentifier)

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Image(systemName: icon(for: task.riskLevel))
                                                .foregroundColor(color(for: task.riskLevel))
                                                .frame(width: 16)
                                            Text(task.title)
                                                .font(.headline)
                                                .strikethrough(isCompleted, color: theme.mutedText)
                                            if task.riskLevel == .high {
                                                Text("HIGH RISK")
                                                    .font(.caption2.weight(.bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .foregroundColor(theme.critical)
                                                    .background(theme.critical.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        Text(task.subtitle)
                                            .font(.caption)
                                            .foregroundColor(theme.mutedText)
                                            .strikethrough(isCompleted, color: theme.mutedText)
                                    }

                                    Spacer()

                                    Text(task.scheduledTime)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(theme.mutedText)
                                }
                                .accessibilityIdentifier("today.task.row.\(taskIdentifier)")
                                .listRowBackground(theme.sectionBackground)
                            }
                        }
                    }

                    Section("Completion Log") {
                        if appState.completionLogs.isEmpty {
                            emptyStateRow(
                                icon: "clock.arrow.circlepath",
                                title: "No completed tasks yet",
                                subtitle: "Completed actions will appear here for quick verification."
                            )
                        } else {
                            ForEach(Array(appState.completionLogs.suffix(5).reversed()), id: \.id) { log in
                                let taskIdentifier = identifierSlug(for: log.taskTitle)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(log.taskTitle)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(formatted(log.completedAt)) • \(log.sourceType.rawValue.capitalized)")
                                        .font(.caption)
                                        .foregroundColor(theme.mutedText)
                                }
                                .accessibilityIdentifier("today.completion.row.\(taskIdentifier)")
                                .listRowBackground(theme.sectionBackground)
                            }
                        }
                    }

                    Section("Manual Protocol Snapshot") {
                        if appState.currentDocument.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            emptyStateRow(
                                icon: "doc.text",
                                title: "No protocol text yet",
                                subtitle: "Import from screenshot/PDF or edit manually to populate this section."
                            )
                        } else {
                            Text(appState.currentDocument.rawText.replacingOccurrences(of: "|", with: " • "))
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                                .listRowBackground(theme.sectionBackground)
                        }
                    }

                }
                .scrollContentBackground(.hidden)
                .background(theme.background)
                .navigationTitle("Today")
                .sheet(isPresented: $isShowingWalkthrough) {
                    OnboardingView {
                        hasSeenFirstRunWalkthrough = true
                    }
                    .environment(themeController)
                }
                .onAppear {
                    if !hasSeenFirstRunWalkthrough {
                        isShowingWalkthrough = true
                    }
                }
                .alert(
                    "High-Risk Task",
                    isPresented: Binding(
                        get: { pendingHighRiskTask != nil },
                        set: { if !$0 { pendingHighRiskTask = nil } }
                    ),
                    actions: {
                        Button("Cancel", role: .cancel) {
                            pendingHighRiskTask = nil
                        }
                        Button("Continue") {
                            doubleConfirmTask = pendingHighRiskTask
                            pendingHighRiskTask = nil
                        }
                    },
                    message: {
                        Text("This action is marked high risk. Please review once before final confirmation.")
                    }
                )
                .alert(
                    "Final Confirmation",
                    isPresented: Binding(
                        get: { doubleConfirmTask != nil },
                        set: { if !$0 { doubleConfirmTask = nil } }
                    ),
                    actions: {
                        Button("Cancel", role: .cancel) {
                            doubleConfirmTask = nil
                        }
                        Button("Mark Completed", role: .destructive) {
                            guard let task = doubleConfirmTask else {
                                return
                            }
                            appState.completeTask(task, confirmedByUser: true)
                            doubleConfirmTask = nil
                        }
                    },
                    message: {
                        Text("Confirm you have completed this high-risk step exactly as instructed.")
                    }
                )
                .toolbar {
                    if isUITesting {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Trigger High Risk") {
                                if let highRiskTask = appState.todayTasks.first(where: {
                                    $0.riskLevel == .high && !appState.isTaskCompleted($0.id)
                                }) {
                                    pendingHighRiskTask = highRiskTask
                                }
                            }
                            .accessibilityIdentifier("today.ui-test.trigger-high-risk")
                        }
                    }
                }
            }
            .tabItem {
                Label("Today", systemImage: "sun.max")
            }

            NavigationStack {
                ImportSourceView(appState: appState)
            }
            .tabItem {
                Label("Import Instructions", systemImage: "square.and.arrow.down")
            }

            NavigationStack {
                ProtocolEditorView(appState: appState)
            }
            .tabItem {
                Label("Edit", systemImage: "square.and.pencil")
            }

            NavigationStack {
                ChangeReviewView(changeItems: appState.changeItems)
            }
            .tabItem {
                Label("Changes", systemImage: "arrow.triangle.2.circlepath")
            }

            NavigationStack {
                HistoryView(appState: appState)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }

            NavigationStack {
                InventoryView(appState: appState)
            }
            .tabItem {
                Label("Inventory", systemImage: "shippingbox")
            }

            NavigationStack {
                SettingsView(appState: appState)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }

    private func icon(for riskLevel: TaskRiskLevel) -> String {
        switch riskLevel {
        case .low:
            return "checkmark.circle"
        case .medium:
            return "clock.badge.checkmark"
        case .high:
            return "exclamationmark.triangle.fill"
        }
    }

    private func color(for riskLevel: TaskRiskLevel) -> Color {
        switch riskLevel {
        case .low:
            return theme.success
        case .medium:
            return theme.caution
        case .high:
            return theme.critical
        }
    }

    private func handleCompletionTap(_ task: TodayTask, isCompleted: Bool) {
        if isCompleted {
            appState.uncompleteTask(task.id)
            return
        }
        if task.riskLevel == .high {
            pendingHighRiskTask = task
            return
        }
        appState.completeTask(task, confirmedByUser: false)
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formattedDaysLeft(_ days: Double) -> String {
        if days < 1 {
            return "< 1 day"
        }
        return String(format: "%.1f days", days)
    }

    private func identifierSlug(for text: String) -> String {
        let normalized = text.lowercased()
        let slug = normalized.replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        return slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    @ViewBuilder
    private func emptyStateRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(theme.primary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .listRowBackground(theme.sectionBackground)
    }
}

#Preview {
    TodayHomeView(appState: DemoDataFactory.createAppState())
        .environment(ThemeController())
}
