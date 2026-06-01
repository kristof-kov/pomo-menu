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
                    .font(.system(size: 44, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: true))

                HStack(spacing: 12) {
                    ActionButton(
                        title: engine.state == .running ? "Pause" : "Start",
                        symbol: engine.state == .running ? "pause.fill" : "play.fill",
                        isPrimary: true,
                        accentColor: engine.currentSession.color
                      ) {
                          engine.togglePause()
                      }

                    ActionButton(
                        title: "Skip",
                        symbol: "forward.end.fill",
                        isPrimary: false,
                        accentColor: engine.currentSession.color
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

            // 5. Anchored footer controls row
            footerSection
        }
        .frame(width: 280)
        .background(.regularMaterial)
    }

    // MARK: - Top Tabs

    private var topTabs: some View {
        HStack(spacing: 4) {
            TabButton(title: "Pomodoro", isActive: engine.currentSession == .work, activeColor: SessionType.work.color) {
                engine.selectSessionType(.work)
            }
            TabButton(title: "Short", isActive: engine.currentSession == .shortBreak, activeColor: SessionType.shortBreak.color) {
                engine.selectSessionType(.shortBreak)
            }
            TabButton(title: "Long", isActive: engine.currentSession == .longBreak, activeColor: SessionType.longBreak.color) {
                engine.selectSessionType(.longBreak)
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                FooterRow(title: "Statistics...", symbol: "chart.bar") {
                    openWindow(id: "stats")
                }

                FooterRow(title: "Settings...", symbol: "gearshape") {
                    openWindow(id: "settings")
                }

                FooterRow(title: "Quit PomoMenu", symbol: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(6)
        }
    }
}

// MARK: - Footer Row

private struct FooterRow: View {
    let title: String
    let symbol: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 11))
                    .frame(width: 14)
                    .foregroundStyle(isHovered ? .primary : .secondary)

                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isHovered ? Color.primary.opacity(0.06) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: isActive ? .semibold : .medium))
                .foregroundStyle(isActive ? activeColor : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isActive ? activeColor.opacity(0.12) : (isHovered ? Color.primary.opacity(0.03) : Color.clear),
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
    let accentColor: Color
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
            .foregroundStyle(isPrimary ? (isHovered ? .white : accentColor) : .secondary)
            .background(
                isPrimary
                    ? (isHovered ? accentColor : accentColor.opacity(0.12))
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
