import SwiftUI

/// Single-line text field for the user's active task / objective.
struct ObjectiveFieldView: View {
    @Bindable var engine: TimerEngine
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Current Objective", systemImage: "target")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(spacing: 8) {
                TextField("What are you working on?", text: $engine.currentObjective)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isFocused)
                    .onSubmit { isFocused = false }

                if !engine.currentObjective.isEmpty {
                    Button {
                        engine.currentObjective = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isFocused ? engine.currentSession.color.opacity(0.5) : .clear,
                                  lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}
