import SwiftUI
import SwiftData

/// Full analytics sheet presented when the user taps the chart button.
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var allRecords: [SessionRecord]

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Statistics")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Summary cards
                    summaryCards

                    Divider()

                    // Per-task breakdown
                    taskBreakdown

                    // Full record list (last 30)
                    if !allRecords.isEmpty {
                        Divider()
                        recentLog
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 320, height: 420)
        .background(.regularMaterial)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(todayCount)", label: "Today", symbol: "sun.max")
            StatCard(value: "\(weekCount)",  label: "This Week", symbol: "calendar.badge.clock")
            StatCard(value: "\(allRecords.count)", label: "All Time", symbol: "chart.line.uptrend.xyaxis")
        }
    }

    private var todayCount: Int {
        allRecords.filter { $0.isToday && $0.resolvedType == .work }.count
    }

    private var weekCount: Int {
        let start = Calendar.current.startOfWeek(for: .now)
        return allRecords.filter { $0.timestamp >= start && $0.resolvedType == .work }.count
    }

    // MARK: - Task Breakdown

    private var taskBreakdown: some View {
        let tasks = Dictionary(grouping: allRecords.filter { $0.resolvedType == .work && !$0.taskDescription.isEmpty },
                               by: \.taskDescription)
        let sorted = tasks.sorted { $0.value.count > $1.value.count }.prefix(8)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Top Tasks")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            if sorted.isEmpty {
                Text("No tasks tracked yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(sorted, id: \.key) { task, records in
                    HStack {
                        Text(task)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Spacer()
                        Text("\(records.count) 🍅")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    // MARK: - Recent Log

    private var recentLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sessions")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            ForEach(allRecords.prefix(30)) { record in
                HStack(spacing: 8) {
                    Circle()
                        .fill(record.resolvedType.color)
                        .frame(width: 6, height: 6)

                    Text(record.taskDescription.isEmpty ? record.resolvedType.label : record.taskDescription)
                        .font(.system(size: 11))
                        .lineLimit(1)

                    Spacer()

                    Text(record.timestamp.formatted(.dateTime.month().day().hour().minute()))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }
}
