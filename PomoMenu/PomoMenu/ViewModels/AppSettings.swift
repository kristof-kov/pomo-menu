import SwiftUI

/// Centralized, observable user preferences.
/// Uses plain stored properties (tracked by @Observable) with UserDefaults
/// didSet persistence — avoiding the @ObservationIgnored/@AppStorage conflict
/// that prevents SwiftUI from detecting changes and re-rendering.
@Observable
final class AppSettings {

    // MARK: - Timer Durations (seconds)

    var workDuration: Int = UserDefaults.standard.integer(forKey: "workDuration").nonZero(default: 25 * 60) {
        didSet { UserDefaults.standard.set(workDuration, forKey: "workDuration") }
    }

    var shortBreakDuration: Int = UserDefaults.standard.integer(forKey: "shortBreakDuration").nonZero(default: 5 * 60) {
        didSet { UserDefaults.standard.set(shortBreakDuration, forKey: "shortBreakDuration") }
    }

    var longBreakDuration: Int = UserDefaults.standard.integer(forKey: "longBreakDuration").nonZero(default: 15 * 60) {
        didSet { UserDefaults.standard.set(longBreakDuration, forKey: "longBreakDuration") }
    }

    // MARK: - Behavior

    var autoStart: Bool = UserDefaults.standard.bool(forKey: "autoStart") {
        didSet { UserDefaults.standard.set(autoStart, forKey: "autoStart") }
    }

    // MARK: - Menu Bar Style

    var menuBarStyle: MenuBarStyle = MenuBarStyle(rawValue: UserDefaults.standard.string(forKey: "menuBarStyle") ?? "") ?? .compact {
        didSet { UserDefaults.standard.set(menuBarStyle.rawValue, forKey: "menuBarStyle") }
    }
}

// MARK: - Helpers

private extension Int {
    /// Returns self if non-zero, otherwise returns the given default.
    func nonZero(default fallback: Int) -> Int {
        self == 0 ? fallback : self
    }
}

// MARK: - Menu Bar Style

enum MenuBarStyle: String, CaseIterable {
    case compact = "compact"   // "25m" when idle, "MM:SS" when active
    case dot     = "dot"       // colored circle dot
    case full    = "full"      // full "MM:SS" always
}
