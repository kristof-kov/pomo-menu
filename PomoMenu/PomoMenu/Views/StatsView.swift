import SwiftUI
import SwiftData
import Charts
import AppKit
import UniformTypeIdentifiers

/// Dedicated analytics view that opens in a standalone window, styled to match the native macOS Settings/System Settings layout.
/// Fixed size and optimized to fit all content cleanly without scrolling.
struct StatsView: View {
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var allRecords: [SessionRecord]
    
    @State private var selectedRange: TimeRange = .sevenDays
    
    var body: some View {
        VStack(spacing: 10) {
            // Overview metrics card
            HStack(spacing: 12) {
                StatCard(
                    title: "Today",
                    timeLabel: formatTimeFocused(seconds: todaySeconds),
                    sessionsLabel: "\(todayCount) session\(todayCount == 1 ? "" : "s")",
                    symbol: "sun.max"
                )
                StatCard(
                    title: "This Week",
                    timeLabel: formatTimeFocused(seconds: weekSeconds),
                    sessionsLabel: "\(weekCount) session\(weekCount == 1 ? "" : "s")",
                    symbol: "calendar.badge.clock"
                )
                StatCard(
                    title: "All Time",
                    timeLabel: formatTimeFocused(seconds: allTimeSeconds),
                    sessionsLabel: "\(allTimeCount) session\(allTimeCount == 1 ? "" : "s")",
                    symbol: "chart.line.uptrend.xyaxis"
                )
            }
            
            // Focus Distribution Bar Chart Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Focus Distribution")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("\(formatTimeFocused(minutes: selectedRangeTotalMinutes)) focused across \(selectedRangeTotalSessions) work session\(selectedRangeTotalSessions == 1 ? "" : "s")")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    Picker("Range", selection: $selectedRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 130)
                }
                
                if dailyFocusData.allSatisfy({ $0.durationMinutes == 0 }) {
                    VStack {
                        Spacer()
                        Text("No focus sessions tracked in this period.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)
                } else {
                    Chart(dailyFocusData) { item in
                        BarMark(
                            x: .value("Day", selectedRange == .sevenDays ? item.weekdayLabel : item.dayLabel),
                            y: .value("Minutes", item.durationMinutes)
                        )
                        .foregroundStyle(SessionType.work.color)
                        .cornerRadius(2)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let mins = value.as(Double.self) {
                                    if mins >= 60 {
                                        Text(String(format: "%.0fh", mins / 60))
                                    } else {
                                        Text("\(Int(mins))m")
                                    }
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                        }
                    }
                    .frame(height: 110)
                }
            }
            .padding(.all, 10)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            
            // GitHub-style Focus Consistency Heatmap Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Focus Consistency")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("Your daily Pomodoro consistency over the last 12 months.")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    // Heatmap Legend
                    HStack(spacing: 3) {
                        Text("Less")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                        
                        ForEach([Color.secondary.opacity(0.1),
                                 SessionType.work.color.opacity(0.25),
                                 SessionType.work.color.opacity(0.50),
                                 SessionType.work.color.opacity(0.75),
                                 SessionType.work.color.opacity(1.0)], id: \.self) { color in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(color)
                                .frame(width: 6, height: 6)
                        }
                        
                        Text("More")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                let cells = heatmapCells
                if cells.isEmpty {
                    Text("No consistency records found.")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .frame(height: 52)
                } else {
                    Chart(cells) { cell in
                        RectangleMark(
                            x: .value("Week", cell.weekIndex),
                            y: .value("Day", 6 - cell.dayOfWeek),
                            width: .fixed(7.5),
                            height: .fixed(7.5)
                        )
                        .foregroundStyle(cell.intensityColor)
                        .cornerRadius(1.5)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartXScale(domain: 0...52)
                    .chartYScale(domain: 0...6)
                    .frame(height: 72)
                }
            }
            .padding(.all, 10)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            
            // Side-by-Side: Top Focus Areas and Recent Sessions
            HStack(alignment: .top, spacing: 12) {
                // Top Focus Areas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Focus Areas")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    if sortedTasks.isEmpty {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("No objectives tracked yet.")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                        Spacer()
                    } else {
                        VStack(spacing: 6) {
                            ForEach(sortedTasks.prefix(3), id: \.name) { task in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(task.name)
                                            .font(.system(size: 10, weight: .medium))
                                            .lineLimit(1)
                                        Spacer()
                                        Text(formatTimeFocused(seconds: task.seconds))
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(.secondary.opacity(0.1))
                                                .frame(height: 3)
                                            Capsule()
                                                .fill(SessionType.work.color)
                                                .frame(width: geo.size.width * task.ratio, height: 3)
                                        }
                                    }
                                    .frame(height: 3)
                                }
                                .padding(.vertical, 1)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.all, 10)
                .frame(height: 115)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
                
                // Recent Sessions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sessions")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    if allRecords.isEmpty {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("No completed sessions yet.")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                        Spacer()
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(allRecords.prefix(3)) { record in
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(record.resolvedType.color)
                                        .frame(width: 4, height: 4)
                                    
                                    Text(record.taskDescription.isEmpty ? record.resolvedType.label : record.taskDescription)
                                        .font(.system(size: 10))
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(record.timestamp.formatted(.dateTime.month().day().hour().minute()))
                                        .font(.system(size: 8))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 0.5)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.all, 10)
                .frame(height: 115)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 580, height: 540)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    CSVExporter.export(records: allRecords)
                } label: {
                    Label("Export to CSV", systemImage: "square.and.arrow.up")
                }
                .help("Export all session history to a CSV file")
            }
        }
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
    
    private func formatTimeFocused(minutes: Double) -> String {
        formatTimeFocused(seconds: Int(minutes * 60))
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
    
    // MARK: - Daily Focus Chart Computations
    
    private var dailyFocusData: [DailyFocusData] {
        let calendar = Calendar.current
        let now = Date()
        let daysToInclude = selectedRange == .sevenDays ? 7 : 30
        
        var dates: [Date] = []
        for i in (0..<daysToInclude).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                dates.append(calendar.startOfDay(for: date))
            }
        }
        
        let workRecords = allRecords.filter { $0.resolvedType == .work }
        
        return dates.map { date in
            let dayRecords = workRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            let totalSeconds = dayRecords.reduce(0) { $0 + $1.durationSeconds }
            let minutes = Double(totalSeconds) / 60.0
            return DailyFocusData(date: date, durationMinutes: minutes)
        }
    }
    
    private var selectedRangeTotalMinutes: Double {
        dailyFocusData.reduce(0.0) { $0 + $1.durationMinutes }
    }
    
    private var selectedRangeTotalSessions: Int {
        let calendar = Calendar.current
        let daysToInclude = selectedRange == .sevenDays ? 7 : 30
        let cutoffDate = calendar.date(byAdding: .day, value: -daysToInclude, to: Date()) ?? Date()
        return allRecords.filter { $0.resolvedType == .work && $0.timestamp >= cutoffDate }.count
    }
    
    // MARK: - Heatmap Computations
    
    private var heatmapCells: [HeatmapCell] {
        let calendar = Calendar.current
        let now = Date()
        
        let startOfTodayWeek = calendar.startOfWeek(for: now)
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -52, to: startOfTodayWeek) else {
            return []
        }
        
        let workRecords = allRecords.filter { $0.resolvedType == .work }
        let totalDays = 53 * 7
        var cells: [HeatmapCell] = []
        cells.reserveCapacity(totalDays)
        
        var dailyDurations: [Date: Int] = [:]
        for record in workRecords {
            let dayStart = calendar.startOfDay(for: record.timestamp)
            dailyDurations[dayStart, default: 0] += record.durationSeconds
        }
        
        for dayOffset in 0..<totalDays {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                let startOfDay = calendar.startOfDay(for: date)
                let seconds = date > now ? 0 : dailyDurations[startOfDay, default: 0]
                let minutes = Double(seconds) / 60.0
                
                let weekIndex = dayOffset / 7
                let dayOfWeek = dayOffset % 7
                
                cells.append(HeatmapCell(
                    date: date,
                    weekIndex: weekIndex,
                    dayOfWeek: dayOfWeek,
                    minutesFocused: minutes
                ))
            }
        }
        return cells
    }
}

// MARK: - Support Models & Views

private struct DailyFocusData: Identifiable {
    let id = UUID()
    let date: Date
    let durationMinutes: Double
    
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

private struct HeatmapCell: Identifiable {
    let id = UUID()
    let date: Date
    let weekIndex: Int
    let dayOfWeek: Int
    let minutesFocused: Double
    
    var intensityColor: Color {
        let workColor = SessionType.work.color
        if minutesFocused <= 0 {
            return Color.secondary.opacity(0.1)
        } else if minutesFocused < 25 {
            return workColor.opacity(0.25)
        } else if minutesFocused < 50 {
            return workColor.opacity(0.50)
        } else if minutesFocused < 100 {
            return workColor.opacity(0.75)
        } else {
            return workColor.opacity(1.0)
        }
    }
}

private enum TimeRange: String, CaseIterable, Identifiable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    
    var id: String { rawValue }
}

private struct StatCard: View {
    let title: String
    let timeLabel: String
    let sessionsLabel: String
    let symbol: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Text(timeLabel)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Text(sessionsLabel)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all, 10)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }
}

// MARK: - CSV Exporter Utility

fileprivate enum CSVExporter {
    
    static func export(records: [SessionRecord]) {
        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.nameFieldStringValue = "PomoMenu_History.csv"
            panel.title = "Export Session History"
            panel.message = "Choose where to save your Pomodoro session history."
            panel.prompt = "Export"
            
            panel.begin { response in
                guard response == .OK, let url = panel.url else { return }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let csvString = generateCSV(from: records)
                    
                    do {
                        try csvString.write(to: url, atomically: true, encoding: .utf8)
                        
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "Export Successful"
                            alert.informativeText = "Your session history has been successfully exported to \(url.lastPathComponent)."
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    } catch {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "Export Failed"
                            alert.informativeText = "Could not save the CSV file:\n\(error.localizedDescription)"
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }
            }
        }
    }
    
    private static func generateCSV(from records: [SessionRecord]) -> String {
        var csvLines = ["Timestamp,Session Type,Duration (Seconds),Duration (Minutes),Task Description"]
        
        let sortedRecords = records.sorted { $0.timestamp < $1.timestamp }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        for record in sortedRecords {
            let timestampStr = formatter.string(from: record.timestamp)
            let sessionTypeStr = record.resolvedType.label
            let durationSeconds = record.durationSeconds
            let durationMinutes = Double(durationSeconds) / 60.0
            let durationMinutesStr = String(format: "%.1f", durationMinutes)
            let escapedDescription = escapeCSVField(record.taskDescription)
            
            let line = "\(timestampStr),\(sessionTypeStr),\(durationSeconds),\(durationMinutesStr),\(escapedDescription)"
            csvLines.append(line)
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    private static func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
