import SwiftUI
import SwiftData

struct EditWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var workout: Workout
    
    @State private var workoutName: String
    @State private var workoutNotes: String
    
    private let settings = UserSettingsManager.shared
    
    init(workout: Workout) {
        self.workout = workout
        self._workoutName = State(initialValue: workout.name)
        self._workoutNotes = State(initialValue: workout.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Workout Info Section
                Section {
                    TextField("Workout Name", text: $workoutName)
                    
                    TextField("Notes (optional)", text: $workoutNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Workout Info")
                }
                
                // Exercises Section
                Section {
                    ForEach(sortedExercises) { workoutExercise in
                        EditExerciseSection(workoutExercise: workoutExercise)
                    }
                } header: {
                    Text("Exercises")
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var sortedExercises: [WorkoutExercise] {
        workout.exercises?.sorted { $0.order < $1.order } ?? []
    }
    
    private func saveChanges() {
        workout.name = workoutName
        workout.notes = workoutNotes.isEmpty ? nil : workoutNotes
        dismiss()
    }
}

// MARK: - Edit Exercise Section
struct EditExerciseSection: View {
    @Bindable var workoutExercise: WorkoutExercise
    
    private let settings = UserSettingsManager.shared
    
    var body: some View {
        DisclosureGroup {
            ForEach(workoutExercise.sortedSets) { set in
                EditSetRow(set: set, setNumber: setNumber(for: set))
            }
        } label: {
            HStack(spacing: 12) {
                if let exercise = workoutExercise.exercise {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: exercise.primaryMuscle.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                    
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func setNumber(for set: WorkoutSet) -> Int {
        (workoutExercise.sortedSets.firstIndex(where: { $0.id == set.id }) ?? 0) + 1
    }
}

// MARK: - Edit Set Row
struct EditSetRow: View {
    @Bindable var set: WorkoutSet
    let setNumber: Int
    
    private let settings = UserSettingsManager.shared
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("Set \(setNumber)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
            // Weight
            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                    .onChange(of: weightText) { _, newValue in
                        if let value = Double(newValue) {
                            set.weight = settings.convertToLbs(value)
                        }
                    }
                
                Text(settings.weightUnit.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Reps
            HStack(spacing: 4) {
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                    .onChange(of: repsText) { _, newValue in
                        set.reps = Int(newValue) ?? 0
                    }
                
                Text("reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            let displayWeight = settings.convertFromLbs(set.weight)
            weightText = displayWeight > 0 ? settings.formatWeight(set.weight) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
}

#Preview {
    EditWorkoutView(workout: Workout(name: "Test Workout"))
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
