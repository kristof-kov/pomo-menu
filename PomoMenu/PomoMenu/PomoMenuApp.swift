import SwiftUI
import SwiftData

@main
struct PomoMenuApp: App {

    // MARK: - Shared Services (single instances shared across scene)
    private let settings: AppSettings
    private let engine: TimerEngine
    private let hotkeyService = HotkeyService()

    init() {
        let s = AppSettings()
        let e = TimerEngine(settings: s)
        settings = s
        engine = e
        NotificationService().requestAuthorization()
    }

    // MARK: - SwiftData Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SessionRecord.self])
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
                    if settings.hotkeysEnabled {
                        hotkeyService.register { engine.togglePause() }
                    }
                }
                .onChange(of: settings.hotkeysEnabled) { _, enabled in
                    if enabled {
                        hotkeyService.register { engine.togglePause() }
                    } else {
                        hotkeyService.unregister()
                    }
                }
        } label: {
            MenuBarLabel(engine: engine, settings: settings)
        }
        .menuBarExtraStyle(.window)
    }
}

