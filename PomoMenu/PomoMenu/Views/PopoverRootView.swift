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
                VStack(spacing: 12) {
                    TimerSectionView(engine: engine)

                    Divider().padding(.horizontal, 12)

                    VStack(spacing: 10) {
                        ObjectiveFieldView(engine: engine)
                        ConfigPanelView(settings: settings)
                        SessionHistoryView()
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.bottom, 12)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 280, height: 390)
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
            TopBarButton(symbol: "chart.bar", help: "Statistics") {
                openWindow(id: "stats")
            }

            // Quit button
            TopBarButton(symbol: "power", help: "Quit PomoMenu") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Top Bar Button

private struct TopBarButton: View {
    let symbol: String
    let help: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
