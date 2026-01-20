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
    
    var body: some View {
        NavigationStack {
            Form {
                // Template Info Section
                Section {
                    TextField("Template Name", text: $templateName)
                    
                    TextField("Notes (optional)", text: $templateNotes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Template Info")
                }
                
                // Exercises Section
                Section {
                    if templateExercises.isEmpty {
                        ContentUnavailableView {
                            Label("No Exercises", systemImage: "dumbbell")
                        } description: {
                            Text("Add exercises to your template")
                        }
                    } else {
                        ForEach($templateExercises) { $item in
                            TemplateExerciseRow(item: $item)
                        }
                        .onMove(perform: moveExercises)
                        .onDelete(perform: deleteExercises)
                    }
                    
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises")
                } footer: {
                    if !templateExercises.isEmpty {
                        Text("Swipe to delete, drag to reorder")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Create") {
                        saveTemplate()
                    }
                    .fontWeight(.semibold)
                    .disabled(templateName.isEmpty || templateExercises.isEmpty)
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
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        templateExercises.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteExercises(at offsets: IndexSet) {
        templateExercises.remove(atOffsets: offsets)
    }
    
    private func saveTemplate() {
        if let existingTemplate = templateToEdit {
            // Update existing template
            existingTemplate.name = templateName
            existingTemplate.notes = templateNotes.isEmpty ? nil : templateNotes
            
            // Remove old exercises
            if let oldExercises = existingTemplate.exercises {
                for exercise in oldExercises {
                    modelContext.delete(exercise)
                }
            }
            
            // Add new exercises
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
            // Create new template
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let exercise = item.exercise {
                    Image(systemName: exercise.primaryMuscle.icon)
                        .foregroundStyle(.orange)
                    
                    Text(exercise.name)
                        .font(.headline)
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Set Count Stepper
                HStack {
                    Text("Sets:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Stepper("\(item.setCount)", value: $item.setCount, in: 1...10)
                        .labelsHidden()
                    
                    Text("\(item.setCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 20)
                }
            }
        }
        .padding(.vertical, 4)
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
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
                
                // Exercise List
                List(filteredExercises, selection: $tempSelectedExercises) { exercise in
                    HStack {
                        Image(systemName: exercise.primaryMuscle.icon)
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                            
                            Text("\(exercise.primaryMuscle.rawValue) • \(exercise.equipment.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if tempSelectedExercises.contains(exercise.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleExercise(exercise)
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add (\(tempSelectedExercises.count))") {
                        addSelectedExercises()
                    }
                    .fontWeight(.semibold)
                    .disabled(tempSelectedExercises.isEmpty)
                }
            }
        }
    }
    
    private func toggleExercise(_ exercise: Exercise) {
        if tempSelectedExercises.contains(exercise.id) {
            tempSelectedExercises.remove(exercise.id)
        } else {
            tempSelectedExercises.insert(exercise.id)
        }
    }
    
    private func addSelectedExercises() {
        let exercisesToAdd = exercises.filter { tempSelectedExercises.contains($0.id) }
        for exercise in exercisesToAdd {
            // Don't add duplicates
            if !selectedExercises.contains(where: { $0.exercise?.id == exercise.id }) {
                selectedExercises.append(TemplateExerciseItem(exercise: exercise))
            }
        }
        dismiss()
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
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color(.tertiarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateTemplateView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
