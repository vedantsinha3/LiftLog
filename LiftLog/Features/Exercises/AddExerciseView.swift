import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var primaryMuscle: MuscleGroup = .chest
    @State private var secondaryMuscles: Set<MuscleGroup> = []
    @State private var equipment: Equipment = .barbell
    @State private var instructions = ""
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise Name Section
                    nameSection
                    
                    // Primary Muscle Section
                    primaryMuscleSection
                    
                    // Secondary Muscles Section
                    secondaryMusclesSection
                    
                    // Equipment Section
                    equipmentSection
                    
                    // Instructions Section
                    instructionsSection
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.red)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveExercise()
                    } label: {
                        Text("Save")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(canSave ? Color.black : Color.gray.opacity(0.3))
                            )
                            .foregroundStyle(canSave ? .white : .secondary)
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Exercise Name")
                .font(.title3)
                .fontWeight(.bold)
            
            TextField("e.g., Incline Dumbbell Press", text: $name)
                .font(.body)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }
    
    // MARK: - Primary Muscle Section
    private var primaryMuscleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Primary Muscle")
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MuscleGroup.allCases) { muscle in
                        MuscleChip(
                            muscle: muscle,
                            isSelected: primaryMuscle == muscle,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    primaryMuscle = muscle
                                    secondaryMuscles.remove(muscle)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Secondary Muscles Section
    private var secondaryMusclesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Secondary Muscles")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !secondaryMuscles.isEmpty {
                    Text("\(secondaryMuscles.count) selected")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.tertiarySystemBackground)))
                }
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(MuscleGroup.allCases) { muscle in
                    if muscle != primaryMuscle {
                        SecondaryMuscleChip(
                            muscle: muscle,
                            isSelected: secondaryMuscles.contains(muscle),
                            onTap: {
                                withAnimation(.spring(response: 0.25)) {
                                    toggleSecondaryMuscle(muscle)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Equipment Section
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Equipment")
                .font(.title3)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(Equipment.allCases) { equip in
                    EquipmentChip(
                        equipment: equip,
                        isSelected: equipment == equip,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                equipment = equip
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Instructions")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Optional")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, -6)
            
            TextField("How to perform this exercise...", text: $instructions, axis: .vertical)
                .font(.body)
                .lineLimit(4...8)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }
    
    // MARK: - Actions
    private func toggleSecondaryMuscle(_ muscle: MuscleGroup) {
        if secondaryMuscles.contains(muscle) {
            secondaryMuscles.remove(muscle)
        } else {
            secondaryMuscles.insert(muscle)
        }
    }
    
    private func saveExercise() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            primaryMuscle: primaryMuscle,
            secondaryMuscles: Array(secondaryMuscles),
            equipment: equipment,
            instructions: instructions.isEmpty ? nil : instructions,
            isCustom: true
        )
        
        modelContext.insert(exercise)
        dismiss()
    }
}

// MARK: - Muscle Chip
struct MuscleChip: View {
    let muscle: MuscleGroup
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: muscle.icon)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(muscle.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.black : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Secondary Muscle Chip
struct SecondaryMuscleChip: View {
    let muscle: MuscleGroup
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                Text(muscle.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.black : Color(.secondarySystemBackground))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Equipment Chip
struct EquipmentChip: View {
    let equipment: Equipment
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: equipment.icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(equipment.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.black : Color(.secondarySystemBackground))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    AddExerciseView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
