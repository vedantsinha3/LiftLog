import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    let workout: Workout
    
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedExercises: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                filterPillsSection
                
                // Exercise List
                List(filteredExercises, selection: $selectedExercises) { exercise in
                    ExercisePickerRow(
                        exercise: exercise,
                        isSelected: selectedExercises.contains(exercise.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(exercise)
                    }
                }
                .listStyle(.plain)
                
                // Add Button
                if !selectedExercises.isEmpty {
                    addButton
                }
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Pills
    private var filterPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MuscleGroup.allCases) { muscle in
                    Button {
                        withAnimation {
                            if selectedMuscle == muscle {
                                selectedMuscle = nil
                            } else {
                                selectedMuscle = muscle
                            }
                        }
                    } label: {
                        Text(muscle.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedMuscle == muscle ? Color.black : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedMuscle == muscle ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Add Button
    private var addButton: some View {
        Button {
            addSelectedExercises()
        } label: {
            Text("Add \(selectedExercises.count) Exercise\(selectedExercises.count == 1 ? "" : "s")")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Filtered Exercises
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)
            
            let matchesMuscle = selectedMuscle == nil ||
                exercise.primaryMuscle == selectedMuscle ||
                exercise.secondaryMuscles.contains(selectedMuscle!)
            
            return matchesSearch && matchesMuscle
        }
    }
    
    // MARK: - Actions
    private func toggleSelection(_ exercise: Exercise) {
        if selectedExercises.contains(exercise.id) {
            selectedExercises.remove(exercise.id)
        } else {
            selectedExercises.insert(exercise.id)
        }
    }
    
    private func addSelectedExercises() {
        let currentOrder = workout.exercises?.count ?? 0
        
        for (index, exerciseId) in selectedExercises.enumerated() {
            guard let exercise = exercises.first(where: { $0.id == exerciseId }) else { continue }
            
            let workoutExercise = WorkoutExercise(
                order: currentOrder + index,
                workout: workout,
                exercise: exercise
            )
            modelContext.insert(workoutExercise)
            
            // Add one empty set by default
            let initialSet = WorkoutSet(order: 0)
            initialSet.workoutExercise = workoutExercise
            modelContext.insert(initialSet)
        }
        
        dismiss()
    }
}

// MARK: - Exercise Picker Row
struct ExercisePickerRow: View {
    let exercise: Exercise
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection Indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? .green : .secondary)
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(exercise.primaryMuscle.rawValue)
                    Text("•")
                    Text(exercise.equipment.rawValue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    ExercisePickerView(workout: Workout())
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
