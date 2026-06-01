import SwiftUI

/// The main countdown display with Start / Pause / Skip controls.
struct TimerSectionView: View {
    @Bindable var engine: TimerEngine

    var body: some View {
        VStack(spacing: 16) {
            // Session type badge
            HStack(spacing: 6) {
                Image(systemName: engine.currentSession.sfSymbol)
                    .font(.system(size: 12))
                Text(engine.currentSession.label.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.5)
            }
            .foregroundStyle(engine.currentSession.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(engine.currentSession.color.opacity(0.12), in: Capsule())

            // Big countdown
            Text(engine.formattedTime)
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundStyle(.primary)
                .contentTransition(.numericText(countsDown: true))
                .animation(.default, value: engine.remainingSeconds)

            // Progress ring
            ProgressArcView(engine: engine)
                .frame(height: 4)
                .padding(.horizontal, 24)

            // Controls
            HStack(spacing: 20) {
                // Reset
                ControlButton(symbol: "arrow.counterclockwise", size: 14) {
                    engine.reset()
                }
                .opacity(engine.isActive ? 1 : 0.3)

                // Primary: Start / Pause / Resume
                primaryButton

                // Skip
                ControlButton(symbol: "forward.end", size: 14) {
                    engine.skip()
                }
                .opacity(engine.isActive ? 1 : 0.3)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Primary Button

    @ViewBuilder
    private var primaryButton: some View {
        Button(action: engine.togglePause) {
            ZStack {
                Circle()
                    .fill(engine.currentSession.color)
                    .frame(width: 54, height: 54)
                    .shadow(color: engine.currentSession.color.opacity(0.4), radius: 8, y: 4)

                Image(systemName: primarySymbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
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
                    .fill(.secondary.opacity(0.2))
                    .frame(height: 4)

                Capsule()
                    .fill(engine.currentSession.color)
                    .frame(width: geo.size.width * progress, height: 4)
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

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(.secondary.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
    }
}
