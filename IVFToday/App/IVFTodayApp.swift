import SwiftUI
import SwiftData

@main
struct IVFTodayApp: App {
    private let modelContainer: ModelContainer
    @State private var themeController = ThemeController()
    @State private var appState: AppState

    init() {
        let launchArguments = ProcessInfo.processInfo.arguments
        if launchArguments.contains("-ui-testing-skip-onboarding") {
            UserDefaults.standard.set(true, forKey: OnboardingPreferences.hasSeenWalkthroughKey)
        }

        let schema = Schema([PersistedAppStateRecord.self])
        let configuration = ModelConfiguration(schema: schema)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData container: \(error.localizedDescription)")
        }

        let store = AppStateSwiftDataStore(
            modelContext: ModelContext(modelContainer)
        )

        let initialAppState = DemoDataFactory.createAppState(persistenceStore: store)
        if launchArguments.contains("-ui-testing-reset-demo-data") {
            initialAppState.resetToDemoData()
        }
        _appState = State(initialValue: initialAppState)
    }

    var body: some Scene {
        WindowGroup {
            TodayHomeView(appState: appState)
                .environment(themeController)
                .tint(themeController.palette.primary)
                .background(themeController.palette.background)
        }
        .modelContainer(modelContainer)
    }
}
