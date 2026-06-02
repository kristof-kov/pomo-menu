import SwiftUI

/// Root container for the PomoMenu popover window.
/// Styled to match stock macOS menu bar panels (WiFi, Sound, Battery).
struct PopoverRootView: View {
    @Bindable var engine: TimerEngine
    @Bindable var settings: AppSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Mode selector
            modePicker
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

            Divider()

            // Timer display
            VStack(alignment: .leading, spacing: 6) {
                Text(engine.formattedTime)
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: true))

                HStack(spacing: 8) {
                    Button(action: { engine.togglePause() }) {
                        Label(
                            engine.state == .running ? "Pause" : "Start",
                            systemImage: engine.state == .running ? "pause.fill" : "play.fill"
                        )
                    }
                    .controlSize(.small)

                    Button(action: { engine.skip() }) {
                        Label("Skip", systemImage: "forward.end.fill")
                    }
                    .controlSize(.small)
                    .disabled(!engine.isActive)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Tasks
            TaskListView(engine: engine)
                .environment(settings)
                .padding(.vertical, 6)

            Divider()

            // Footer
            VStack(spacing: 2) {
                MenuRow(title: "Statistics…", symbol: "chart.bar") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "stats")
                }
                MenuRow(title: "Settings…", symbol: "gearshape") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }

                Divider()
                    .padding(.horizontal, 8)

                MenuRow(title: "Quit PomoMenu", symbol: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 280)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            ModeTab(title: "Pomodoro", isActive: engine.currentSession == .work) {
                engine.selectSessionType(.work)
            }
            ModeTab(title: "Short", isActive: engine.currentSession == .shortBreak) {
                engine.selectSessionType(.shortBreak)
            }
            ModeTab(title: "Long", isActive: engine.currentSession == .longBreak) {
                engine.selectSessionType(.longBreak)
            }
        }
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Mode Tab (segmented control style)

private struct ModeTab: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    isActive ? Color.primary.opacity(0.08) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Menu Row (NSMenu-style full-width hover row)

private struct MenuRow: View {
    let title: String
    let symbol: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.system(size: 13))

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isHovered ? Color.accentColor.opacity(0.8) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(isHovered ? .white : .primary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
