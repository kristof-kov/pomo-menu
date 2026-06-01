import SwiftUI

/// The type of a Pomodoro interval.
enum SessionType: String, Codable, CaseIterable {
    case work       = "Work"
    case shortBreak = "Short Break"
    case longBreak  = "Long Break"

    var defaultDuration: TimeInterval {
        switch self {
        case .work:       return 25 * 60
        case .shortBreak: return  5 * 60
        case .longBreak:  return 15 * 60
        }
    }

    var label: String { rawValue }

    /// Accent color used in the UI for each session type.
    var color: Color {
        switch self {
        case .work:       return Color(hue: 0.02, saturation: 0.75, brightness: 0.90)  // warm red
        case .shortBreak: return Color(hue: 0.55, saturation: 0.70, brightness: 0.85)  // teal
        case .longBreak:  return Color(hue: 0.60, saturation: 0.65, brightness: 0.80)  // indigo
        }
    }

    var sfSymbol: String {
        switch self {
        case .work:       return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak:  return "moon.zzz"
        }
    }
}
