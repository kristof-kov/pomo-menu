import SwiftUI

/// Compact menu bar label rendered inside `MenuBarExtra`.
/// Switches between a dot, short label, or full timer based on user preference.
struct MenuBarLabel: View {
    let engine: TimerEngine
    let settings: AppSettings

    var body: some View {
        Group {
            switch settings.menuBarStyle {
            case .dot:
                dotView
            case .full:
                Text(engine.isActive ? engine.formattedTime : sessionShortName)
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .medium))
            case .compact:
                Text(engine.isActive ? engine.shortLabel : sessionShortName)
                    .font(.system(size: 12, weight: .medium))
            }
        }
    }

    // MARK: - Sub-views

    private var dotView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .shadow(color: dotColor.opacity(0.6), radius: engine.state == .running ? 3 : 0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true),
                           value: engine.state == .running)
            if engine.isActive {
                Text(engine.shortLabel)
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
        }
    }

    private var dotColor: Color {
        switch engine.state {
        case .running: return engine.currentSession.color
        case .paused:  return .secondary
        default:       return .secondary
        }
    }

    private var sessionShortName: String {
        switch engine.currentSession {
        case .work:       return "🍅"
        case .shortBreak: return "☕"
        case .longBreak:  return "🌙"
        }
    }
}
