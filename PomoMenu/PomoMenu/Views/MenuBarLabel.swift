import SwiftUI

/// Compact menu bar label rendered inside `MenuBarExtra`.
/// Switches between dot mode, compact string, or full timer based on user preference.
struct MenuBarLabel: View {
    let engine: TimerEngine
    let settings: AppSettings

    var body: some View {
        Group {
            switch settings.menuBarStyle {
            case .dot:
                dotView
            case .full:
                Text(engine.isActive ? engine.formattedTime : "🍅")
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .medium))
            case .compact:
                Text(engine.isActive ? engine.shortLabel : "🍅")
                    .font(.system(size: 12, weight: .medium))
            }
        }
    }

    // MARK: - Dot Mode

    /// Dot mode behaviour:
    ///  - Idle / Finished → 🍅 emoji
    ///  - Work running    → solid white circle (SF Symbol)
    ///  - Break running   → semi-transparent white circle
    ///  - Paused          → dimmed version of the above
    @ViewBuilder
    private var dotView: some View {
        switch engine.state {
        case .idle, .finished:
            Text("🍅")
                .font(.system(size: 14))

        case .running:
            Image(systemName: "circle.fill")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color.white)
                .opacity(engine.currentSession == .work ? 1.0 : 0.4)

        case .paused:
            Image(systemName: "circle.fill")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color.white)
                .opacity(engine.currentSession == .work ? 0.55 : 0.25)
        }
    }
}
