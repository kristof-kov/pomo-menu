import SwiftUI

/// A native macOS settings / preferences view that opens in a standalone window.
struct SettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section(header: Text("Interval Durations").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                DurationSettingRow(label: "Work Duration", symbol: "brain.head.profile", minutes: $settings.workDuration)
                DurationSettingRow(label: "Short Break",  symbol: "cup.and.saucer",       minutes: $settings.shortBreakDuration)
                DurationSettingRow(label: "Long Break",   symbol: "moon.zzz",             minutes: $settings.longBreakDuration)
            }

            Section(header: Text("Preferences").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                Toggle(isOn: $settings.autoStart) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.trianglehead.clockwise")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("Auto-Start Next Session")
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Picker(selection: $settings.menuBarStyle) {
                    Text("Compact (25m)").tag(MenuBarStyle.compact)
                    Text("Full Timer").tag(MenuBarStyle.full)
                    Text("Dot Mode").tag(MenuBarStyle.dot)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "menubar.rectangle")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("Menu Bar Icon Style")
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 340)
    }
}

// MARK: - Duration Setting Row

private struct DurationSettingRow: View {
    let label: String
    let symbol: String
    @Binding var minutes: Int

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

            HStack(spacing: 4) {
                DurationSettingButton(symbol: "minus") {
                    if minutes > 60 { minutes -= 60 }
                }

                Text("\(displayMinutes)m")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .frame(width: 32, alignment: .center)

                DurationSettingButton(symbol: "plus") {
                    if minutes < 60 * 60 { minutes += 60 }
                }
            }
        }
    }
}

// MARK: - Duration Setting Button

private struct DurationSettingButton: View {
    let symbol: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 18, height: 18)
                .background(isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
