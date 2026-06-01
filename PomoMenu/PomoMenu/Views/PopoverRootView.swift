import SwiftUI

/// Root container for the menu bar popover dropdown.
/// Assembles all sub-sections into a clean, scrollable vertical layout.
struct PopoverRootView: View {
    @Bindable var engine: TimerEngine
    @Bindable var settings: AppSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: app title
            topBar

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    TimerSectionView(engine: engine)

                    Divider().padding(.horizontal, 12)

                    VStack(spacing: 10) {
                        ObjectiveFieldView(engine: engine)
                        SessionHistoryView()
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 10)
            }
            .frame(maxHeight: .infinity)

            footerSection
        }
        .frame(width: 260, height: 345)
        .background(.regularMaterial)
    }


    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Image(systemName: "timer")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(engine.currentSession.color)
            Text("PomoMenu")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 0) {
            Divider()

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
