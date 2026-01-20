import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedEquipment: Equipment?
    @State private var showingFilters = false
    @State private var showingAddExercise = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                filterPillsSection
                
                // Exercise List
                List {
                    ForEach(filteredExercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRowView(exercise: exercise)
                        }
                    }
                    .onDelete(perform: deleteExercises)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView()
            }
        }
    }
    
    // MARK: - Filter Pills
    private var filterPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Muscle Group Filter
                Menu {
                    Button("All Muscles") {
                        selectedMuscle = nil
                    }
                    Divider()
                    ForEach(MuscleGroup.allCases) { muscle in
                        Button {
                            selectedMuscle = muscle
                        } label: {
                            if selectedMuscle == muscle {
                                Label(muscle.rawValue, systemImage: "checkmark")
                            } else {
                                Text(muscle.rawValue)
                            }
                        }
                    }
                } label: {
                    FilterPill(
                        title: selectedMuscle?.rawValue ?? "Muscle",
                        isActive: selectedMuscle != nil,
                        icon: "figure.strengthtraining.traditional"
                    )
                }
                
                // Equipment Filter
                Menu {
                    Button("All Equipment") {
                        selectedEquipment = nil
                    }
                    Divider()
                    ForEach(Equipment.allCases) { equipment in
                        Button {
                            selectedEquipment = equipment
                        } label: {
                            if selectedEquipment == equipment {
                                Label(equipment.rawValue, systemImage: "checkmark")
                            } else {
                                Text(equipment.rawValue)
                            }
                        }
                    }
                } label: {
                    FilterPill(
                        title: selectedEquipment?.rawValue ?? "Equipment",
                        isActive: selectedEquipment != nil,
                        icon: "dumbbell.fill"
                    )
                }
                
                // Clear Filters
                if selectedMuscle != nil || selectedEquipment != nil {
                    Button {
                        withAnimation {
                            selectedMuscle = nil
                            selectedEquipment = nil
                        }
                    } label: {
                        Text("Clear")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
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
            
            let matchesEquipment = selectedEquipment == nil || 
                exercise.equipment == selectedEquipment
            
            return matchesSearch && matchesMuscle && matchesEquipment
        }
    }
    
    // MARK: - Actions
    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = filteredExercises[index]
            if exercise.isCustom {
                modelContext.delete(exercise)
            }
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isActive: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.subheadline)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? Color.orange.opacity(0.15) : Color(.secondarySystemBackground))
        .foregroundStyle(isActive ? .orange : .primary)
        .clipShape(Capsule())
    }
}

// MARK: - Exercise Row
struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 12) {
            // Muscle Icon
            Image(systemName: exercise.primaryMuscle.icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(Color.orange.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if exercise.isCustom {
                        Text("Custom")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 8) {
                    Label(exercise.primaryMuscle.rawValue, systemImage: "target")
                    Label(exercise.equipment.rawValue, systemImage: exercise.equipment.icon)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
