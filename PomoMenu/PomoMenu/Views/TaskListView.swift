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
    @State private var hoveredTaskId: UUID? = nil
    @State private var editingTaskId: UUID? = nil
    @State private var editingTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                VStack(spacing: 6) {
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
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Task")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(SessionType.work.color)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: isTextFieldFocused) { focused in
            if !focused {
                if let id = editingTaskId, let task = tasks.first(where: { $0.id == id }) {
                    saveEditing(task)
                }
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
                toggleTaskCompletion(task)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(task.isCompleted ? .secondary : SessionType.work.color)
            }
            .buttonStyle(.plain)

            // Task title area: Editable TextField if in editing mode, else standard interactive Button
            if editingTaskId == task.id {
                TextField("", text: $editingTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        saveEditing(task)
                    }
                    .onExitCommand {
                        cancelEditing()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button {
                    if !task.isCompleted {
                        if engine.activeTaskId == task.id {
                            // Selected task clicked again -> Enter inline editing
                            startEditing(task)
                        } else {
                            engine.activeTaskId = task.id
                            engine.currentObjective = task.title
                        }
                    }
                } label: {
                    HStack {
                        Text(task.title)
                            .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)
                            .strikethrough(task.isCompleted)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        // Pomodoro progress (completed / estimated)
                        Text("(\(task.completedPomos)/\(task.estimatedPomos))")
                            .font(.system(size: 11, weight: .medium).monospacedDigit())
                            .foregroundStyle(isActive ? SessionType.work.color : .secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(task.isCompleted)
                .onTapGesture(count: 2) {
                    if !task.isCompleted {
                        startEditing(task)
                    }
                }
            }

            // Delete button (revealed dynamically on hover)
            Button {
                deleteTask(task)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .opacity(hoveredTaskId == task.id ? 1.0 : 0.0)
            .disabled(hoveredTaskId != task.id)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            isActive ? SessionType.work.color.opacity(0.08) : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isActive ? SessionType.work.color.opacity(0.18) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredTaskId = hovering ? task.id : nil
            }
        }
        .contextMenu {
            Button {
                toggleTaskCompletion(task)
            } label: {
                Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete", systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }

            Button {
                startEditing(task)
            } label: {
                Label("Rename Task", systemImage: "pencil")
            }

            Button {
                resetTaskProgress(task)
            } label: {
                Label("Reset Progress", systemImage: "arrow.counterclockwise")
            }

            Menu("Completed Pomos (\(task.completedPomos))") {
                Button("+1 Done") {
                    adjustCompletedPomos(task, by: 1)
                }
                Button("-1 Done") {
                    adjustCompletedPomos(task, by: -1)
                }
            }

            Menu("Estimated Pomos (\(task.estimatedPomos))") {
                Button("+1 Est") {
                    adjustEstimatedPomos(task, by: 1)
                }
                Button("-1 Est") {
                    adjustEstimatedPomos(task, by: -1)
                }
            }

            if !task.isCompleted {
                Button {
                    engine.activeTaskId = task.id
                    engine.currentObjective = task.title
                } label: {
                    Label("Focus on Task", systemImage: "target")
                }
            }

            Divider()

            Button(role: .destructive) {
                deleteTask(task)
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
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

    // MARK: - Task Row Secondary Actions

    private func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        if task.isCompleted && engine.activeTaskId == task.id {
            engine.activeTaskId = nil
            engine.currentObjective = ""
        }
        try? modelContext.save()
    }

    private func resetTaskProgress(_ task: TaskItem) {
        task.completedPomos = 0
        try? modelContext.save()
    }

    private func deleteTask(_ task: TaskItem) {
        if engine.activeTaskId == task.id {
            engine.activeTaskId = nil
            engine.currentObjective = ""
        }
        modelContext.delete(task)
        try? modelContext.save()
    }

    private func adjustCompletedPomos(_ task: TaskItem, by amount: Int) {
        let newCount = task.completedPomos + amount
        if newCount >= 0 {
            task.completedPomos = newCount
            try? modelContext.save()
        }
    }

    private func adjustEstimatedPomos(_ task: TaskItem, by amount: Int) {
        let newCount = task.estimatedPomos + amount
        if newCount >= 1 {
            task.estimatedPomos = newCount
            try? modelContext.save()
        }
    }

    // MARK: - Inline Editing Actions

    private func startEditing(_ task: TaskItem) {
        editingTaskId = task.id
        editingTitle = task.title
        isTextFieldFocused = true
    }

    private func saveEditing(_ task: TaskItem) {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            task.title = trimmed
            if engine.activeTaskId == task.id {
                engine.currentObjective = trimmed
            }
            try? modelContext.save()
        }
        editingTaskId = nil
    }

    private func cancelEditing() {
        editingTaskId = nil
    }
}
