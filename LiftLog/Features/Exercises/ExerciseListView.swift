import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedEquipment: Equipment?
    @State private var showingAddExercise = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                filterPillsSection
                
                // Exercise List
                if filteredExercises.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.secondarySystemBackground)))
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No Exercises Found")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if selectedMuscle != nil || selectedEquipment != nil {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMuscle = nil
                        selectedEquipment = nil
                    }
                } label: {
                    Text("Clear Filters")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Exercise List
    private var exerciseList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(filteredExercises) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        ExerciseRowView(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Filter Pills
    private var filterPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Muscle Group Filter
                Menu {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMuscle = nil
                        }
                    } label: {
                        HStack {
                            Text("All Muscles")
                            if selectedMuscle == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(MuscleGroup.allCases) { muscle in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMuscle = muscle
                            }
                        } label: {
                            HStack {
                                Text(muscle.rawValue)
                                if selectedMuscle == muscle {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    ExerciseFilterPill(
                        title: selectedMuscle?.rawValue ?? "Muscle",
                        isActive: selectedMuscle != nil,
                        icon: "figure.strengthtraining.traditional"
                    )
                }
                
                // Equipment Filter
                Menu {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedEquipment = nil
                        }
                    } label: {
                        HStack {
                            Text("All Equipment")
                            if selectedEquipment == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(Equipment.allCases) { equipment in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedEquipment = equipment
                            }
                        } label: {
                            HStack {
                                Text(equipment.rawValue)
                                if selectedEquipment == equipment {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    ExerciseFilterPill(
                        title: selectedEquipment?.rawValue ?? "Equipment",
                        isActive: selectedEquipment != nil,
                        icon: "dumbbell.fill"
                    )
                }
                
                // Clear Filters
                if selectedMuscle != nil || selectedEquipment != nil {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMuscle = nil
                            selectedEquipment = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("Clear")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.primary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
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
}

// MARK: - Exercise Filter Pill
struct ExerciseFilterPill: View {
    let title: String
    let isActive: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .fontWeight(.semibold)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Image(systemName: "chevron.down")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isActive ? Color.black : Color(.secondarySystemBackground))
        .foregroundStyle(isActive ? .white : .primary)
        .clipShape(Capsule())
    }
}

// MARK: - Exercise Row
struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 14) {
            // Muscle Icon
            Circle()
                .fill(Color.black)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: exercise.primaryMuscle.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if exercise.isCustom {
                        Text("Custom")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.12))
                            )
                            .foregroundStyle(.blue)
                    }
                }
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption2)
                        Text(exercise.primaryMuscle.rawValue)
                            .font(.caption)
                    }
                    
                    Text("•")
                        .font(.caption)
                    
                    HStack(spacing: 4) {
                        Image(systemName: exercise.equipment.icon)
                            .font(.caption2)
                        Text(exercise.equipment.rawValue)
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
