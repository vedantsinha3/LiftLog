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
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Primary Muscle") {
                    Picker("Primary Muscle", selection: $primaryMuscle) {
                        ForEach(MuscleGroup.allCases) { muscle in
                            Text(muscle.rawValue).tag(muscle)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Secondary Muscles") {
                    ForEach(MuscleGroup.allCases) { muscle in
                        if muscle != primaryMuscle {
                            Button {
                                toggleSecondaryMuscle(muscle)
                            } label: {
                                HStack {
                                    Text(muscle.rawValue)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if secondaryMuscles.contains(muscle) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Equipment") {
                    Picker("Equipment", selection: $equipment) {
                        ForEach(Equipment.allCases) { equip in
                            Text(equip.rawValue).tag(equip)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Instructions (Optional)") {
                    TextField("How to perform this exercise...", text: $instructions, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveExercise()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
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

#Preview {
    AddExerciseView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
