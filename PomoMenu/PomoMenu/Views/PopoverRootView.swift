import SwiftUI

/// Root container for the menu bar popover dropdown.
/// Assembles all sub-sections into a clean, scrollable vertical layout.
struct PopoverRootView: View {
    @Bindable var engine: TimerEngine
    @Bindable var settings: AppSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: app title + stat/quit buttons
            topBar

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    TimerSectionView(engine: engine)

                    Divider().padding(.horizontal, 16)

                    VStack(spacing: 14) {
                        ObjectiveFieldView(engine: engine)
                        ConfigPanelView(settings: settings)
                        SessionHistoryView()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 300, height: 520)
        .background(.regularMaterial)
    }


    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 0) {
            // App name
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(engine.currentSession.color)
                Text("PomoMenu")
                    .font(.system(size: 13, weight: .semibold))
            }

            Spacer()

            // Stats button
            Button { openWindow(id: "stats") } label: {
                Image(systemName: "chart.bar")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.secondary.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Statistics")

            // Quit button
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.secondary.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Quit PomoMenu")
            .padding(.leading, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
