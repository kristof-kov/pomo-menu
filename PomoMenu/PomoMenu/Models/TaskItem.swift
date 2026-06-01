import Foundation
import SwiftData

/// Represents a user task with estimated and completed Pomodoro counts.
@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var completedPomos: Int
    var estimatedPomos: Int
    var createdAt: Date

    init(title: String, estimatedPomos: Int = 1) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.completedPomos = 0
        self.estimatedPomos = estimatedPomos
        self.createdAt = Date()
    }
}
