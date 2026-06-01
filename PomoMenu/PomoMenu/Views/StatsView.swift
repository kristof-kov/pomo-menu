import SwiftUI
import SwiftData

/// Dedicated analytics view that opens in a standalone window, styled to match the Settings window.
struct StatsView: View {
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var allRecords: [SessionRecord]

    var body: some View {
        Form {
            // Overview section with sleek column headers
            Section(header: Text("Overview").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                HStack(spacing: 0) {
                    StatColumn(value: "\(todayCount)", label: "Today", symbol: "sun.max")
                    Divider().padding(.vertical, 4)
                    StatColumn(value: "\(weekCount)",  label: "This Week", symbol: "calendar.badge.clock")
                    Divider().padding(.vertical, 4)
                    StatColumn(value: "\(allRecords.filter { $0.resolvedType == .work }.count)", label: "All Time", symbol: "chart.line.uptrend.xyaxis")
                }
                .padding(.vertical, 4)
            }

            // Top tasks completed
            Section(header: Text("Top Focus Areas").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                if sortedTasks.isEmpty {
                    Text("No objectives tracked yet.")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(sortedTasks.prefix(5), id: \.key) { task, records in
                        HStack {
                            Text(task)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            Text("\(records.count) completed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Recent activity log
            if !allRecords.isEmpty {
                Section(header: Text("Recent Sessions").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(allRecords.prefix(8)) { record in
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

    // MARK: - Computations

    private var todayCount: Int {
        allRecords.filter { $0.isToday && $0.resolvedType == .work }.count
    }

    private var weekCount: Int {
        let start = Calendar.current.startOfWeek(for: .now)
        return allRecords.filter { $0.timestamp >= start && $0.resolvedType == .work }.count
    }

    private var sortedTasks: [(key: String, value: [SessionRecord])] {
        let tasks = Dictionary(grouping: allRecords.filter { $0.resolvedType == .work && !$0.taskDescription.isEmpty },
                               by: \.taskDescription)
        return tasks.sorted { $0.value.count > $1.value.count }.map { (key: $0.key, value: $0.value) }
    }
}

// MARK: - Stat Column

private struct StatColumn: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
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
