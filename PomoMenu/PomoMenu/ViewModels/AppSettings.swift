import SwiftUI

/// Centralized, observable user preferences backed by AppStorage.
/// Injected as an environment object so any view can read/write settings.
@Observable
final class AppSettings {

    // MARK: - Timer Durations (seconds)
    @ObservationIgnored
    @AppStorage("workDuration") private var _workDuration: Int = 25 * 60
    var workDuration: Int {
        get { _workDuration }
        set { _workDuration = newValue }
    }

    @ObservationIgnored
    @AppStorage("shortBreakDuration") private var _shortBreakDuration: Int = 5 * 60
    var shortBreakDuration: Int {
        get { _shortBreakDuration }
        set { _shortBreakDuration = newValue }
    }

    @ObservationIgnored
    @AppStorage("longBreakDuration") private var _longBreakDuration: Int = 15 * 60
    var longBreakDuration: Int {
        get { _longBreakDuration }
        set { _longBreakDuration = newValue }
    }

    // MARK: - Behavior
    @ObservationIgnored
    @AppStorage("autoStart") private var _autoStart: Bool = false
    var autoStart: Bool {
        get { _autoStart }
        set { _autoStart = newValue }
    }

    @ObservationIgnored
    @AppStorage("hotkeysEnabled") private var _hotkeysEnabled: Bool = true
    var hotkeysEnabled: Bool {
        get { _hotkeysEnabled }
        set { _hotkeysEnabled = newValue }
    }

    // MARK: - Menu Bar Style
    @ObservationIgnored
    @AppStorage("menuBarStyle") private var _menuBarStyle: String = MenuBarStyle.compact.rawValue
    var menuBarStyle: MenuBarStyle {
        get { MenuBarStyle(rawValue: _menuBarStyle) ?? .compact }
        set { _menuBarStyle = newValue.rawValue }
    }
}

enum MenuBarStyle: String, CaseIterable {
    case compact  = "compact"   // "25m" or "24:59"
    case dot      = "dot"       // colored circle dot
    case full     = "full"      // full "MM:SS" always
}
