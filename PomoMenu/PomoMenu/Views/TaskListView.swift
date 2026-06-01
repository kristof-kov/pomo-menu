import SwiftUI
import SwiftData

enum ActiveCountField: Hashable {
    case completed(UUID)
    case estimated(UUID)
}

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

    @State private var activeCountField: ActiveCountField? = nil
    @State private var tempCountText: String = ""
    @FocusState private var isCountFieldFocused: Bool

    @State private var isTasksExpanded = true

    /// IDs of recently-completed tasks in the 1-second grace window before hiding.
    @State private var justCompletedIds: Set<UUID> = []

    @Environment(AppSettings.self) private var settings

    // MARK: - Sorted / Filtered Task Lists

    /// Incomplete tasks sorted by createdAt, then completed tasks sorted by createdAt.
    private var sortedTasks: [TaskItem] {
        let incomplete = tasks.filter { !$0.isCompleted }.sorted { $0.createdAt < $1.createdAt }
        let completed  = tasks.filter {  $0.isCompleted }.sorted { $0.createdAt < $1.createdAt }
        return incomplete + completed
    }

    /// The display list — completed tasks hidden (except grace-window ones) when setting is on.
    private var visibleTasks: [TaskItem] {
        if settings.hideCompletedTasks {
            return sortedTasks.filter { !$0.isCompleted || justCompletedIds.contains($0.id) }
        }
        return sortedTasks
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header toggle button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isTasksExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Tasks")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    if !tasks.isEmpty && !isTasksExpanded {
                        let incompleteCount = tasks.filter { !$0.isCompleted }.count
                        Text("(\(incompleteCount))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isTasksExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 2)

            if isTasksExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    if visibleTasks.isEmpty && !isAddingTask {
                        emptyState
                    } else {
                        ForEach(visibleTasks) { task in
                            taskRow(for: task)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // [+ Add Task] row
                    if isAddingTask {
                        addTaskForm
                    } else {
                        addTaskButton
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: visibleTasks.map(\.id))
                .transition(.opacity)
            }
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            if !focused {
                if let id = editingTaskId, let task = tasks.first(where: { $0.id == id }) {
                    saveEditing(task)
                }
            }
        }
        .onChange(of: isCountFieldFocused) { _, focused in
            if !focused {
                if let field = activeCountField {
                    switch field {
                    case .completed(let id), .estimated(let id):
                        if let task = tasks.first(where: { $0.id == id }) {
                            saveCountEditing(task)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Task Row View

    @ViewBuilder
    private func taskRow(for task: TaskItem) -> some View {
        let isActive = engine.activeTaskId == task.id
        let isHovered = hoveredTaskId == task.id

        HStack(spacing: 8) {
            // Checkbox
            Button {
                toggleTaskCompletion(task)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(task.isCompleted ? .secondary : (isActive ? engine.currentSession.color : .secondary))
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
                    Text(task.title)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(task.isCompleted ? .secondary : (isActive ? engine.currentSession.color : .primary))
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

            Spacer()

            // Pomodoro progress (completed / estimated input badge with standardized size)
            HStack(spacing: 3) {
                // Completed/Done Count
                if case .completed(let taskId) = activeCountField, taskId == task.id {
                    TextField("", text: $tempCountText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                        .foregroundStyle(isActive ? engine.currentSession.color : .secondary)
                        .multilineTextAlignment(.center)
                        .focused($isCountFieldFocused)
                        .onSubmit {
                            saveCountEditing(task)
                        }
                        .onExitCommand {
                            cancelCountEditing()
                        }
                        .frame(width: 16, height: 16, alignment: .center)
                } else {
                    Text("\(task.completedPomos)")
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                        .foregroundStyle(isActive ? engine.currentSession.color : .secondary)
                        .frame(width: 16, height: 16, alignment: .center)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !task.isCompleted {
                                startCountEditing(task, field: .completed(task.id))
                            }
                        }
                }

                Text("/")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .frame(height: 16)

                // Estimated Count
                if case .estimated(let taskId) = activeCountField, taskId == task.id {
                    TextField("", text: $tempCountText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                        .foregroundStyle(isActive ? engine.currentSession.color : .secondary)
                        .multilineTextAlignment(.center)
                        .focused($isCountFieldFocused)
                        .onSubmit {
                            saveCountEditing(task)
                        }
                        .onExitCommand {
                            cancelCountEditing()
                        }
                        .frame(width: 16, height: 16, alignment: .center)
                } else {
                    Text("\(task.estimatedPomos)")
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                        .foregroundStyle(isActive ? engine.currentSession.color : .secondary)
                        .frame(width: 16, height: 16, alignment: .center)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !task.isCompleted {
                                startCountEditing(task, field: .estimated(task.id))
                            }
                        }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.clear)

            // Delete button (revealed dynamically on hover)
            Button {
                deleteTask(task)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.0)
            .disabled(!isHovered)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            isHovered ? Color.accentColor.opacity(0.8) : Color.clear,
            in: RoundedRectangle(cornerRadius: 4)
        )
        .foregroundStyle(isHovered ? .white : .primary)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
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

    private var addTaskButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAddingTask = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Add Task")
                    .font(.system(size: 13))
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    private var addTaskForm: some View {
        VStack(spacing: 6) {
            TextField("Task title…", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .controlSize(.small)
                .onSubmit(saveTask)

            HStack {
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

                HStack(spacing: 8) {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isAddingTask = false
                            newTaskTitle = ""
                            newTaskEstPomos = 1
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                    Button("Save") {
                        saveTask()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
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
        let completing = !task.isCompleted
        task.isCompleted = completing

        if completing {
            if engine.activeTaskId == task.id {
                engine.activeTaskId = nil
                engine.currentObjective = ""
            }
            if settings.hideCompletedTasks {
                justCompletedIds.insert(task.id)
                let completedId = task.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        _ = self.justCompletedIds.remove(completedId)
                    }
                }
            }
        } else {
            _ = justCompletedIds.remove(task.id)
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
        _ = justCompletedIds.remove(task.id)
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

    // MARK: - Completed / Estimated Count Inline Editing Actions

    private func startCountEditing(_ task: TaskItem, field: ActiveCountField) {
        activeCountField = field
        switch field {
        case .completed:
            tempCountText = "\(task.completedPomos)"
        case .estimated:
            tempCountText = "\(task.estimatedPomos)"
        }
        isCountFieldFocused = true
    }

    private func saveCountEditing(_ task: TaskItem) {
        guard let field = activeCountField else { return }
        let trimmed = tempCountText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let parsed = Int(trimmed) {
            switch field {
            case .completed:
                if parsed >= 0 {
                    task.completedPomos = parsed
                    try? modelContext.save()
                }
            case .estimated:
                if parsed >= 1 {
                    task.estimatedPomos = parsed
                    try? modelContext.save()
                }
            }
        }
        activeCountField = nil
    }

    private func cancelCountEditing() {
        activeCountField = nil
    }
}
