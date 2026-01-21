import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    
    var body: some View {
        ScrollView(showsIndicators: false) {
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
            .padding(20)
        }
        .background(Color(.systemBackground))
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Large Icon
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 100, height: 100)
                
                Image(systemName: exercise.primaryMuscle.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 6) {
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if exercise.isCustom {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("Custom Exercise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Details
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Details")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                ExerciseDetailRow(
                    icon: "target",
                    title: "Primary Muscle",
                    value: exercise.primaryMuscle.rawValue,
                    gradient: [.orange, .red]
                )
                
                if !exercise.secondaryMuscles.isEmpty {
                    Divider()
                        .padding(.leading, 56)
                    
                    ExerciseDetailRow(
                        icon: "scope",
                        title: "Secondary",
                        value: exercise.secondaryMuscles.map { $0.rawValue }.joined(separator: ", "),
                        gradient: [.blue, .cyan]
                    )
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ExerciseDetailRow(
                    icon: exercise.equipment.icon,
                    title: "Equipment",
                    value: exercise.equipment.rawValue,
                    gradient: [.green, .mint]
                )
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Instructions
    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Instructions")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(instructions)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }
}

// MARK: - Exercise Detail Row
struct ExerciseDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(gradient.first ?? .gray)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: ExerciseDataLoader.sampleExercise())
    }
}
