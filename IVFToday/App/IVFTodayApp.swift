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
        modelContainer = Self.makeModelContainer(for: schema)

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
                // Current release palettes are tuned for light appearance.
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
    }

    private static func makeModelContainer(for schema: Schema) -> ModelContainer {
        do {
            let configuration = ModelConfiguration(schema: schema)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // If the persistent store becomes unreadable on device, fall back to an
            // in-memory container so the app still boots instead of hard-crashing.
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Failed to create any SwiftData container: \(error.localizedDescription)")
            }
        }
    }
}
