import SwiftUI
import SwiftData

struct CreateTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var templateToEdit: WorkoutTemplate?
    
    @State private var templateName: String = ""
    @State private var templateNotes: String = ""
    @State private var templateExercises: [TemplateExerciseItem] = []
    @State private var showingExercisePicker = false
    
    private var isEditing: Bool {
        templateToEdit != nil
    }
    
    private var canSave: Bool {
        !templateName.isEmpty && !templateExercises.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Template Info Section
                    templateInfoSection
                    
                    // Exercises Section
                    exercisesSection
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveTemplate()
                    } label: {
                        Text(isEditing ? "Save" : "+  Create ")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(canSave ? Color.black : Color.gray.opacity(0))
                            )
                            .foregroundStyle(canSave ? .white : .secondary)
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                TemplateExercisePickerView(selectedExercises: $templateExercises)
            }
            .onAppear {
                loadTemplateData()
            }
        }
    }
    
    // MARK: - Template Info Section
    private var templateInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Template Info")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("NAME")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    
                    TextField("e.g., Push Day, Leg Day", text: $templateName)
                        .font(.body)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                
                // Notes Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("NOTES (OPTIONAL)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    
                    TextField("Add any notes about this template...", text: $templateNotes, axis: .vertical)
                        .font(.body)
                        .lineLimit(2...4)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Exercises")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !templateExercises.isEmpty {
                    Text("\(templateExercises.count) total")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.tertiarySystemBackground)))
                }
            }
            
            VStack(spacing: 10) {
                if templateExercises.isEmpty {
                    // Empty State
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)
                        
                        Text("No exercises added")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                } else {
                    ForEach($templateExercises) { $item in
                        TemplateExerciseRow(
                            item: $item,
                            onDelete: {
                                withAnimation(.spring(response: 0.3)) {
                                    templateExercises.removeAll { $0.id == item.id }
                                }
                            }
                        )
                    }
                }
                
                // Add Exercise Button
                Button {
                    showingExercisePicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    )
                    .foregroundStyle(.primary)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Actions
    private func loadTemplateData() {
        guard let template = templateToEdit else { return }
        
        templateName = template.name
        templateNotes = template.notes ?? ""
        templateExercises = template.sortedExercises.map { templateExercise in
            TemplateExerciseItem(
                exercise: templateExercise.exercise,
                setCount: templateExercise.defaultSetCount,
                defaultWeight: templateExercise.defaultWeight,
                defaultReps: templateExercise.defaultReps
            )
        }
    }
    
    private func saveTemplate() {
        if let existingTemplate = templateToEdit {
            existingTemplate.name = templateName
            existingTemplate.notes = templateNotes.isEmpty ? nil : templateNotes
            
            if let oldExercises = existingTemplate.exercises {
                for exercise in oldExercises {
                    modelContext.delete(exercise)
                }
            }
            
            for (index, item) in templateExercises.enumerated() {
                let templateExercise = TemplateExercise(
                    order: index,
                    defaultSetCount: item.setCount,
                    defaultWeight: item.defaultWeight,
                    defaultReps: item.defaultReps,
                    template: existingTemplate,
                    exercise: item.exercise
                )
                modelContext.insert(templateExercise)
            }
        } else {
            let template = WorkoutTemplate(name: templateName, notes: templateNotes.isEmpty ? nil : templateNotes)
            modelContext.insert(template)
            
            for (index, item) in templateExercises.enumerated() {
                let templateExercise = TemplateExercise(
                    order: index,
                    defaultSetCount: item.setCount,
                    defaultWeight: item.defaultWeight,
                    defaultReps: item.defaultReps,
                    template: template,
                    exercise: item.exercise
                )
                modelContext.insert(templateExercise)
            }
        }
        
        dismiss()
    }
}

// MARK: - Template Exercise Item (Local State)
struct TemplateExerciseItem: Identifiable {
    let id = UUID()
    var exercise: Exercise?
    var setCount: Int = 3
    var defaultWeight: Double?
    var defaultReps: Int?
}

// MARK: - Template Exercise Row
struct TemplateExerciseRow: View {
    @Binding var item: TemplateExerciseItem
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise Icon
            if let exercise = item.exercise {
                Circle()
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: exercise.primaryMuscle.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(exercise.primaryMuscle.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Set Count Stepper
            HStack(spacing: 8) {
                Button {
                    if item.setCount > 1 {
                        item.setCount -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(.tertiarySystemBackground)))
                        .foregroundStyle(item.setCount > 1 ? .primary : .tertiary)
                }
                .disabled(item.setCount <= 1)
                
                Text("\(item.setCount)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(width: 24)
                
                Button {
                    if item.setCount < 10 {
                        item.setCount += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(.tertiarySystemBackground)))
                        .foregroundStyle(item.setCount < 10 ? .primary : .tertiary)
                }
                .disabled(item.setCount >= 10)
            }
            
            // Delete Button
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(.tertiarySystemBackground)))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Template Exercise Picker
struct TemplateExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @Binding var selectedExercises: [TemplateExerciseItem]
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var tempSelectedExercises: Set<UUID> = []
    
    var filteredExercises: [Exercise] {
        var result = exercises
        
        if let muscleGroup = selectedMuscleGroup {
            result = result.filter { $0.primaryMuscle == muscleGroup }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Muscle Group Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedMuscleGroup == nil,
                            action: { selectedMuscleGroup = nil }
                        )
                        
                        ForEach(MuscleGroup.allCases) { muscle in
                            FilterChip(
                                title: muscle.rawValue,
                                isSelected: selectedMuscleGroup == muscle,
                                action: { selectedMuscleGroup = muscle }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.secondarySystemBackground))
                
                // Exercise List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredExercises) { exercise in
                            TemplateExercisePickerRow(
                                exercise: exercise,
                                isSelected: tempSelectedExercises.contains(exercise.id),
                                onTap: { toggleExercise(exercise) }
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addSelectedExercises()
                    } label: {
                        Text("Add (\(tempSelectedExercises.count))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(tempSelectedExercises.isEmpty ? Color.gray.opacity(0.3) : Color.black)
                            )
                            .foregroundColor(tempSelectedExercises.isEmpty ? .secondary : .white)
                    }
                    .disabled(tempSelectedExercises.isEmpty)
                }
            }
        }
    }
    
    private func toggleExercise(_ exercise: Exercise) {
        withAnimation(.spring(response: 0.25)) {
            if tempSelectedExercises.contains(exercise.id) {
                tempSelectedExercises.remove(exercise.id)
            } else {
                tempSelectedExercises.insert(exercise.id)
            }
        }
    }
    
    private func addSelectedExercises() {
        let exercisesToAdd = exercises.filter { tempSelectedExercises.contains($0.id) }
        for exercise in exercisesToAdd {
            if !selectedExercises.contains(where: { $0.exercise?.id == exercise.id }) {
                selectedExercises.append(TemplateExerciseItem(exercise: exercise))
            }
        }
        dismiss()
    }
}

// MARK: - Template Exercise Picker Row
struct TemplateExercisePickerRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Exercise Icon
                Circle()
                    .fill(isSelected ? Color.black : Color(.tertiarySystemBackground))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: exercise.primaryMuscle.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : .primary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("\(exercise.primaryMuscle.rawValue) • \(exercise.equipment.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : Color(.systemGray3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.black.opacity(0.05) : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color(.tertiarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    CreateTemplateView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
