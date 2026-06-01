import SwiftUI

/// Root container for the redesigned PomoMenu main window popover.
/// Implements minimal top tabs, centered monospaced large countdown timer,
/// Start / Skip control actions, interactive checklists, and anchored utility footer.
struct PopoverRootView: View {
    @Bindable var engine: TimerEngine
    @Bindable var settings: AppSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // 1. Top tabs for manual mode select
            topTabs
                .padding(.vertical, 6)

            Divider()

            // 2. Large centered countdown & control actions
            VStack(spacing: 10) {
                Text(engine.formattedTime)
                    .font(.system(size: 44, weight: .regular, design: .monospaced))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: true))

                HStack(spacing: 12) {
                    ActionButton(
                        title: engine.state == .running ? "Pause" : "Start",
                        symbol: engine.state == .running ? "pause.fill" : "play.fill",
                        isPrimary: true
                      ) {
                          engine.togglePause()
                      }

                    ActionButton(
                        title: "Skip",
                        symbol: "forward.end.fill",
                        isPrimary: false
                    ) {
                        engine.skip()
                    }
                    .disabled(!engine.isActive)
                    .opacity(engine.isActive ? 1.0 : 0.4)
                }
            }
            .padding(.vertical, 14)

            Divider()

            // 3. Interactive Tasks checklist area (fully dynamic, intrinsic height)
            TaskListView(engine: engine)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            // 4. Anchored footer controls row
            footerSection
        }
        .frame(width: 280)
        .background(.regularMaterial)
    }

    // MARK: - Top Tabs

    private var topTabs: some View {
        HStack(spacing: 4) {
            TabButton(title: "Pomodoro", isActive: engine.currentSession == .work) {
                engine.selectSessionType(.work)
            }
            TabButton(title: "Short", isActive: engine.currentSession == .shortBreak) {
                engine.selectSessionType(.shortBreak)
            }
            TabButton(title: "Long", isActive: engine.currentSession == .longBreak) {
                engine.selectSessionType(.longBreak)
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: 0) {
            FooterIconButton(symbol: "gearshape", help: "Settings...") {
                openWindow(id: "settings")
            }

            Spacer()

            FooterIconButton(symbol: "chart.bar", help: "Statistics...") {
                openWindow(id: "stats")
            }

            Spacer()

            FooterIconButton(symbol: "power", help: "Quit PomoMenu") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: isActive ? .semibold : .medium))
                .foregroundStyle(isActive ? .primary : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isActive ? Color.primary.opacity(0.08) : (isHovered ? Color.primary.opacity(0.03) : Color.clear),
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let title: String
    let symbol: String
    let isPrimary: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(width: 80, height: 24)
            .foregroundStyle(isPrimary ? (isHovered ? .white : SessionType.work.color) : .secondary)
            .background(
                isPrimary
                    ? (isHovered ? SessionType.work.color : SessionType.work.color.opacity(0.12))
                    : (isHovered ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03)),
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Footer Icon Button

private struct FooterIconButton: View {
    let symbol: String
    let help: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .background(isHovered ? Color.primary.opacity(0.06) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
