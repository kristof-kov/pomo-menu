import SwiftUI
import SwiftData

/// Dedicated analytics view that opens in a standalone window, styled to match the Settings window.
struct StatsView: View {
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var allRecords: [SessionRecord]

    var body: some View {
        Form {
            // Overview section with sleek column headers & actual focused times
            Section(header: Text("Overview").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                HStack(spacing: 0) {
                    StatColumn(
                        timeLabel: formatTimeFocused(seconds: todaySeconds),
                        sessionsLabel: "\(todayCount) session\(todayCount == 1 ? "" : "s")",
                        title: "Today",
                        symbol: "sun.max"
                    )
                    Divider().padding(.vertical, 4)
                    StatColumn(
                        timeLabel: formatTimeFocused(seconds: weekSeconds),
                        sessionsLabel: "\(weekCount) session\(weekCount == 1 ? "" : "s")",
                        title: "This Week",
                        symbol: "calendar.badge.clock"
                    )
                    Divider().padding(.vertical, 4)
                    StatColumn(
                        timeLabel: formatTimeFocused(seconds: allTimeSeconds),
                        sessionsLabel: "\(allTimeCount) session\(allTimeCount == 1 ? "" : "s")",
                        title: "All Time",
                        symbol: "chart.line.uptrend.xyaxis"
                    )
                }
                .padding(.vertical, 4)
            }

            // Top tasks completed with visual duration bars
            Section(header: Text("Top Focus Areas").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                if sortedTasks.isEmpty {
                    Text("No objectives tracked yet.")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(sortedTasks.prefix(4), id: \.name) { task in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(task.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                Text(formatTimeFocused(seconds: task.seconds))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }

                            // Visual progress bar representing percentage of total focus time
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(.secondary.opacity(0.1))
                                        .frame(height: 5)
                                    Capsule()
                                        .fill(SessionType.work.color)
                                        .frame(width: geo.size.width * task.ratio, height: 5)
                                }
                            }
                            .frame(height: 5)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Recent activity log
            if !allRecords.isEmpty {
                Section(header: Text("Recent Sessions").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(allRecords.prefix(5)) { record in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(record.resolvedType.color)
                                    .frame(width: 5, height: 5)

                                Text(record.taskDescription.isEmpty ? record.resolvedType.label : record.taskDescription)
                                    .font(.system(size: 11))
                                    .lineLimit(1)

                                Spacer()

                                Text(record.timestamp.formatted(.dateTime.month().day().hour().minute()))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 340)
    }

    // MARK: - Computations & Formatting

    private func formatTimeFocused(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private var todaySeconds: Int {
        allRecords.filter { $0.isToday && $0.resolvedType == .work }.reduce(0) { $0 + $1.durationSeconds }
    }

    private var todayCount: Int {
        allRecords.filter { $0.isToday && $0.resolvedType == .work }.count
    }

    private var weekSeconds: Int {
        let start = Calendar.current.startOfWeek(for: .now)
        return allRecords.filter { $0.timestamp >= start && $0.resolvedType == .work }.reduce(0) { $0 + $1.durationSeconds }
    }

    private var weekCount: Int {
        let start = Calendar.current.startOfWeek(for: .now)
        return allRecords.filter { $0.timestamp >= start && $0.resolvedType == .work }.count
    }

    private var allTimeSeconds: Int {
        allRecords.filter { $0.resolvedType == .work }.reduce(0) { $0 + $1.durationSeconds }
    }

    private var allTimeCount: Int {
        allRecords.filter { $0.resolvedType == .work }.count
    }

    private var sortedTasks: [(name: String, seconds: Int, ratio: Double)] {
        let workRecords = allRecords.filter { $0.resolvedType == .work && !$0.taskDescription.isEmpty }
        let totalWorkSeconds = workRecords.reduce(0) { $0 + $1.durationSeconds }
        let grouped = Dictionary(grouping: workRecords, by: \.taskDescription)
        
        let mapped = grouped.map { (key: String, value: [SessionRecord]) -> (name: String, seconds: Int, ratio: Double) in
            let secs = value.reduce(0) { $0 + $1.durationSeconds }
            let rat = totalWorkSeconds > 0 ? Double(secs) / Double(totalWorkSeconds) : 0.0
            return (name: key, seconds: secs, ratio: rat)
        }
        
        return mapped.sorted { $0.seconds > $1.seconds }
    }
}

// MARK: - Stat Column

private struct StatColumn: View {
    let timeLabel: String
    let sessionsLabel: String
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Text(timeLabel)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(sessionsLabel)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }
}
