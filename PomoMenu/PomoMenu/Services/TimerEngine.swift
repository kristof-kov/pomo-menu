import Foundation
import Combine
import SwiftData

// MARK: - Timer State Machine

enum TimerState {
    case idle
    case running
    case paused
    case finished
}

// MARK: - Timer Engine

/// Central @Observable service managing the Pomodoro timer lifecycle.
/// Drives the countdown via a Combine `Timer.publish` pipeline.
@Observable
final class TimerEngine {

    // MARK: - Published State
    var state: TimerState = .idle
    var currentSession: SessionType = .work
    var remainingSeconds: Int = Int(SessionType.work.defaultDuration)
    var currentObjective: String = ""
    var activeTaskId: UUID?

    /// Counts completed work sessions (resets after longBreak cycle).
    var completedWorkInCycle: Int = 0

    // MARK: - Injected Dependencies
    private var modelContext: ModelContext?
    private let notifications = NotificationService()
    private let settings: AppSettings

    // MARK: - Combine
    private var cancellable: AnyCancellable?

    init(settings: AppSettings) {
        self.settings = settings
        resetToCurrentSession()
    }

    // MARK: - Public Control API

    func setModelContext(_ ctx: ModelContext) {
        self.modelContext = ctx
    }

    func selectSessionType(_ type: SessionType) {
        cancellable?.cancel()
        state = .idle
        currentSession = type
        resetToCurrentSession()
    }

    func start() {
        guard state == .idle || state == .paused || state == .finished else { return }
        if state == .finished { advanceToNextSession() }
        state = .running
        startTicking()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        cancellable?.cancel()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        startTicking()
    }

    func togglePause() {
        switch state {
        case .running: pause()
        case .paused:  resume()
        case .idle, .finished: start()
        }
    }

    func skip() {
        guard state == .running || state == .paused else { return }
        cancellable?.cancel()
        // Skip does not count as a completed session — no persist, no notification,
        // no cycle counter increment. Just move directly to the next interval.
        advanceToNextSession()
        state = .idle
    }

    func reset() {
        cancellable?.cancel()
        state = .idle
        resetToCurrentSession()
    }

    // MARK: - Private Helpers

    private func startTicking() {
        cancellable?.cancel()
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            finishSession(skipped: false)
            return
        }
        remainingSeconds -= 1
    }

    private func finishSession(skipped: Bool) {
        cancellable?.cancel()
        state = .finished

        // Persist record only for naturally completed sessions
        if !skipped {
            persistRecord()
            incrementActiveTaskPomo()
            notifications.postSessionEndNotification(sessionType: currentSession,
                                                     nextSession: nextSessionType())
        }

        if currentSession == .work {
            completedWorkInCycle += 1
        }

        if settings.autoStart {
            advanceToNextSession()
            state = .idle   // must be .idle before start() so start() doesn't advance again
            start()
        } else {
            advanceToNextSession()
            state = .idle
        }
    }

    private func incrementActiveTaskPomo() {
        guard let ctx = modelContext, let id = activeTaskId, currentSession == .work else { return }
        let descriptor = FetchDescriptor<TaskItem>()
        if let tasks = try? ctx.fetch(descriptor) {
            if let task = tasks.first(where: { $0.id == id }) {
                task.completedPomos += 1
                try? ctx.save()
            }
        }
    }

    private func advanceToNextSession() {
        currentSession = nextSessionType()
        resetToCurrentSession()
    }

    private func nextSessionType() -> SessionType {
        switch currentSession {
        case .work:
            // Every 4 work sessions triggers a long break
            return (completedWorkInCycle % 4 == 0 && completedWorkInCycle > 0)
                ? .longBreak
                : .shortBreak
        case .shortBreak, .longBreak:
            if currentSession == .longBreak { completedWorkInCycle = 0 }
            return .work
        }
    }

    private func resetToCurrentSession() {
        remainingSeconds = durationFor(currentSession)
    }

    private func durationFor(_ type: SessionType) -> Int {
        switch type {
        case .work:       return settings.workDuration
        case .shortBreak: return settings.shortBreakDuration
        case .longBreak:  return settings.longBreakDuration
        }
    }

    private func persistRecord() {
        guard let ctx = modelContext else { return }
        let totalDuration = durationFor(currentSession)
        let elapsed = totalDuration - remainingSeconds
        let record = SessionRecord(
            sessionType: currentSession,
            taskDescription: currentObjective,
            durationSeconds: elapsed
        )
        ctx.insert(record)
        try? ctx.save()
    }

    // MARK: - Computed Helpers

    var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var shortLabel: String {
        let m = remainingSeconds / 60
        return "\(m)m"
    }

    var isActive: Bool {
        state == .running || state == .paused
    }

    /// Total seconds for the current session (used by progress arc).
    var totalSecondsForCurrentSession: Int {
        durationFor(currentSession)
    }
}
