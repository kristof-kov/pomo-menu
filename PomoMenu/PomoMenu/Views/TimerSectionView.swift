import SwiftUI

/// The main countdown display with Start / Pause / Skip controls.
struct TimerSectionView: View {
    @Bindable var engine: TimerEngine

    var body: some View {
        VStack(spacing: 14) {
            // Big countdown & Session type subtitle
            VStack(spacing: 6) {
                Text(engine.formattedTime)
                    .font(.system(size: 38, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: engine.remainingSeconds)

                HStack(spacing: 5) {
                    Image(systemName: engine.currentSession.sfSymbol)
                        .font(.system(size: 10, weight: .medium))
                    Text(engine.currentSession.label)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(engine.currentSession.color)
            }

            // Progress bar
            ProgressArcView(engine: engine)
                .frame(height: 3)
                .padding(.horizontal, 20)

            // Controls
            HStack(spacing: 24) {
                // Reset
                ControlButton(symbol: "arrow.counterclockwise", size: 13) {
                    engine.reset()
                }
                .disabled(!engine.isActive)
                .opacity(engine.isActive ? 1 : 0.3)

                // Primary: Start / Pause / Resume
                primaryButton

                // Skip
                ControlButton(symbol: "forward.end", size: 13) {
                    engine.skip()
                }
                .disabled(!engine.isActive)
                .opacity(engine.isActive ? 1 : 0.3)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Primary Button

    @ViewBuilder
    private var primaryButton: some View {
        Button(action: engine.togglePause) {
            Image(systemName: primarySymbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(engine.currentSession.color)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: engine.state)
    }

    private var primarySymbol: String {
        switch engine.state {
        case .running:         return "pause.fill"
        case .paused:          return "play.fill"
        case .idle, .finished: return "play.fill"
        }
    }
}

// MARK: - Progress Arc

private struct ProgressArcView: View {
    let engine: TimerEngine

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.15))
                    .frame(height: 3)

                Capsule()
                    .fill(engine.currentSession.color)
                    .frame(width: geo.size.width * progress, height: 3)
                    .animation(.linear(duration: 1), value: engine.remainingSeconds)
            }
        }
    }

    private var progress: Double {
        let total = engine.totalSecondsForCurrentSession
        guard total > 0 else { return 0 }
        return Double(engine.remainingSeconds) / Double(total)
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let symbol: String
    let size: CGFloat
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
