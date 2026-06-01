import UserNotifications
import AppKit

/// Thin wrapper around UNUserNotificationCenter for session-end alerts.
final class NotificationService {

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func postSessionEndNotification(sessionType: SessionType, nextSession: SessionType, soundName: String, enableNotifications: Bool) {
        if soundName != "None (Silent)" {
            // Play native macOS system sound effect
            NSSound(named: NSSound.Name(soundName))?.play()
        }

        guard enableNotifications else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch sessionType {
        case .work:
            content.title = "Pomodoro Complete 🍅"
            content.body  = "Great work! Time for a \(nextSession.label.lowercased())."
        case .shortBreak:
            content.title = "Break Over"
            content.body  = "Ready to focus? Your work session starts now."
        case .longBreak:
            content.title = "Long Break Over"
            content.body  = "You're refreshed. Let's get back to it!"
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil     // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }
}
