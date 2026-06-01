import SwiftUI
import SwiftData

/// Interactive todo checklist supporting Pomodoro estimates, target focus, and status toggle.
struct TaskListView: View {
    @Bindable var engine: TimerEngine
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]

    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskEstPomos = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Tasks:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
            }
            .padding(.bottom, 2)

            // Tasks items list
            if tasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 4) {
                    ForEach(tasks) { task in
                        taskRow(for: task)
                    }
                }
            }

            // [+ Add Task] row
            if isAddingTask {
                addTaskForm
            } else {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isAddingTask = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add Task")
                            .font(.system(size: 12))
                        Spacer()
                    }
                    .foregroundStyle(SessionType.work.color)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Task Row View

    @ViewBuilder
    private func taskRow(for task: TaskItem) -> some View {
        let isActive = engine.activeTaskId == task.id

        HStack(spacing: 8) {
            // Checkbox
            Button {
                task.isCompleted.toggle()
                if task.isCompleted && engine.activeTaskId == task.id {
                    engine.activeTaskId = nil
                    engine.currentObjective = ""
                }
                try? modelContext.save()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundStyle(task.isCompleted ? .secondary : SessionType.work.color)
            }
            .buttonStyle(.plain)

            // Task title button (tap to activate / focus)
            Button {
                if !task.isCompleted {
                    engine.activeTaskId = task.id
                    engine.currentObjective = task.title
                }
            } label: {
                HStack {
                    Text(task.title)
                        .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    // Pomodoro progress (completed / estimated)
                    Text("(\(task.completedPomos)/\(task.estimatedPomos))")
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                        .foregroundStyle(isActive ? SessionType.work.color : .secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(task.isCompleted)

            // Delete button
            Button {
                if engine.activeTaskId == task.id {
                    engine.activeTaskId = nil
                    engine.currentObjective = ""
                }
                modelContext.delete(task)
                try? modelContext.save()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            isActive ? SessionType.work.color.opacity(0.08) : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isActive ? SessionType.work.color.opacity(0.18) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Add Task Form

    private var addTaskForm: some View {
        VStack(spacing: 6) {
            TextField("Task title...", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                .onSubmit(saveTask)

            HStack {
                // Est stepper
                HStack(spacing: 2) {
                    Text("Est:")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    Button { if newTaskEstPomos > 1 { newTaskEstPomos -= 1 } } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 8, weight: .bold))
                            .frame(width: 14, height: 14)
                            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                    }
                    .buttonStyle(.plain)

                    Text("\(newTaskEstPomos)")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .frame(width: 12, alignment: .center)

                    Button { if newTaskEstPomos < 10 { newTaskEstPomos += 1 } } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .bold))
                            .frame(width: 14, height: 14)
                            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Cancel & Save buttons
                HStack(spacing: 8) {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isAddingTask = false
                            newTaskTitle = ""
                            newTaskEstPomos = 1
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                    Button("Save") {
                        saveTask()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(SessionType.work.color)
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(6)
        .background(.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }

    private func saveTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let task = TaskItem(title: trimmed, estimatedPomos: newTaskEstPomos)
        modelContext.insert(task)
        try? modelContext.save()

        if engine.activeTaskId == nil {
            engine.activeTaskId = task.id
            engine.currentObjective = task.title
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            newTaskTitle = ""
            newTaskEstPomos = 1
            isAddingTask = false
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text("No tasks left. Add one below!")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.vertical, 4)
            Spacer()
        }
    }
}
