import SwiftUI

/// Collapsible configuration panel for adjusting interval durations and behavior toggles.
struct ConfigPanelView: View {
    @Bindable var settings: AppSettings
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("Settings", systemImage: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    Divider()

                    // Duration steppers
                    DurationRow(label: "Work",         symbol: "brain.head.profile",  minutes: $settings.workDuration)
                    DurationRow(label: "Short Break",  symbol: "cup.and.saucer",       minutes: $settings.shortBreakDuration)
                    DurationRow(label: "Long Break",   symbol: "moon.zzz",             minutes: $settings.longBreakDuration)

                    Divider()

                    // Toggles
                    SettingToggle(label: "Auto-Start Intervals", symbol: "arrow.trianglehead.clockwise", value: $settings.autoStart)

                    Divider()

                    // Menu bar style picker
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Menu Bar Style", systemImage: "menubar.rectangle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)

                        Picker("", selection: $settings.menuBarStyle) {
                            Text("Compact (25m)").tag(MenuBarStyle.compact)
                            Text("Full Timer").tag(MenuBarStyle.full)
                            Text("Dot").tag(MenuBarStyle.dot)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding(.horizontal, 2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Duration Row

private struct DurationRow: View {
    let label: String
    let symbol: String
    @Binding var minutes: Int   // stored as seconds internally

    private var displayMinutes: Int {
        get { minutes / 60 }
    }

    var body: some View {
        HStack {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(label)
                .font(.system(size: 12))

            Spacer()

            HStack(spacing: 3) {
                DurationRowButton(symbol: "minus") {
                    if minutes > 60 { minutes -= 60 }
                }

                Text("\(displayMinutes)m")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .frame(width: 32, alignment: .center)

                DurationRowButton(symbol: "plus") {
                    if minutes < 60 * 60 { minutes += 60 }
                }
            }
        }
    }
}

// MARK: - Duration Row Button

private struct DurationRowButton: View {
    let symbol: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 20, height: 20)
                .background(isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Setting Toggle

private struct SettingToggle: View {
    let label: String
    let symbol: String
    @Binding var value: Bool

    var body: some View {
        Toggle(isOn: $value) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 12))
            }
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
    }
}
