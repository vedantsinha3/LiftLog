import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Details
                detailsSection
                
                // Instructions
                if let instructions = exercise.instructions, !instructions.isEmpty {
                    instructionsSection(instructions)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: exercise.primaryMuscle.icon)
                .font(.system(size: 56))
                .foregroundStyle(.orange.gradient)
                .frame(width: 100, height: 100)
                .background(Color.orange.opacity(0.15))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if exercise.isCustom {
                    Text("Custom Exercise")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Details
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                DetailRow(
                    icon: "target",
                    title: "Primary Muscle",
                    value: exercise.primaryMuscle.rawValue,
                    color: .orange
                )
                
                if !exercise.secondaryMuscles.isEmpty {
                    DetailRow(
                        icon: "scope",
                        title: "Secondary Muscles",
                        value: exercise.secondaryMuscles.map { $0.rawValue }.joined(separator: ", "),
                        color: .blue
                    )
                }
                
                DetailRow(
                    icon: exercise.equipment.icon,
                    title: "Equipment",
                    value: exercise.equipment.rawValue,
                    color: .green
                )
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Instructions
    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(instructions)
                .font(.body)
                .foregroundStyle(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: ExerciseDataLoader.sampleExercise())
    }
}
