import SwiftUI
import SwiftData

/// Scrollable list of today's completed sessions using @Query filtered to today.
struct SessionHistoryView: View {
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var allRecords: [SessionRecord]

    private var todayRecords: [SessionRecord] {
        allRecords.filter(\.isToday)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Label("Today", systemImage: "calendar")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer()

                if !todayRecords.isEmpty {
                    Text("\(todayRecords.count) sessions")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            if todayRecords.isEmpty {
                emptyState
            } else {
                ForEach(todayRecords) { record in
                    SessionRowView(record: record)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.tertiary)
                Text("No sessions yet today")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            Spacer()
        }
    }
}

// MARK: - Session Row

private struct SessionRowView: View {
    let record: SessionRecord

    var body: some View {
        HStack(spacing: 10) {
            // Type indicator
            Circle()
                .fill(record.resolvedType.color)
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.taskDescription.isEmpty ? record.resolvedType.label : record.taskDescription)
                    .font(.system(size: 12))
                    .lineLimit(1)

                Text(record.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text("\(record.durationSeconds / 60)m")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
    }
}
