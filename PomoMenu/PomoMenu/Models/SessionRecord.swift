import Foundation
import SwiftData

/// Persistent record of a completed Pomodoro session stored via SwiftData.
@Model
final class SessionRecord {
    var timestamp: Date
    var sessionType: String          // SessionType.rawValue
    var taskDescription: String
    var durationSeconds: Int

    init(
        timestamp: Date = .now,
        sessionType: SessionType,
        taskDescription: String,
        durationSeconds: Int
    ) {
        self.timestamp = timestamp
        self.sessionType = sessionType.rawValue
        self.taskDescription = taskDescription
        self.durationSeconds = durationSeconds
    }

    var resolvedType: SessionType {
        SessionType(rawValue: sessionType) ?? .work
    }

    /// Returns true if this record was created today.
    var isToday: Bool {
        Calendar.current.isDateInToday(timestamp)
    }
}
