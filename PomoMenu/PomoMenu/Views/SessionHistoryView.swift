import SwiftUI
import SwiftData

/// Scrollable list of today's completed sessions using @Query filtered to today.
struct SessionHistoryView: View {
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var allRecords: [SessionRecord]
    @State private var isExpanded = false

    private var todayRecords: [SessionRecord] {
        allRecords.filter(\.isToday)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header toggle button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("Today's History", systemImage: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    if !todayRecords.isEmpty && !isExpanded {
                        Text("(\(todayRecords.count))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    Divider().padding(.bottom, 4)

                    if todayRecords.isEmpty {
                        emptyState
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 6) {
                                ForEach(todayRecords) { record in
                                    SessionRowView(record: record)
                                }
                            }
                        }
                        .frame(maxHeight: 90)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
                Text("No sessions yet today")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
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
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.taskDescription.isEmpty ? record.resolvedType.label : record.taskDescription)
                    .font(.system(size: 11))
                    .lineLimit(1)

                Text(record.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text("\(record.durationSeconds / 60)m")
                .font(.system(size: 10, weight: .medium).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }
}
