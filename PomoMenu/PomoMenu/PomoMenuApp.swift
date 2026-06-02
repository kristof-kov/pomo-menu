import SwiftUI
import SwiftData

@main
struct PomoMenuApp: App {

    // MARK: - Shared Services (single instances shared across scene)
    private let settings: AppSettings
    private let engine: TimerEngine

    init() {
        let s = AppSettings()
        let e = TimerEngine(settings: s)
        settings = s
        engine = e
        NotificationService().requestAuthorization()
    }

    // MARK: - SwiftData Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SessionRecord.self, TaskItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView(engine: engine, settings: settings)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    engine.setModelContext(sharedModelContainer.mainContext)
                }
        } label: {
            MenuBarLabel(engine: engine, settings: settings)
        }
        .menuBarExtraStyle(.window)

        Window("Statistics", id: "stats") {
            StatsView()
                .modelContainer(sharedModelContainer)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Settings", id: "settings") {
            SettingsView(settings: settings)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

