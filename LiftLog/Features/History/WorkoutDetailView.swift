    import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Card
                summaryCard
                
                // Exercises
                exercisesSection
                
                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Workout?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 16) {
            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.orange)
                Text(formattedDate)
                    .font(.subheadline)
                Spacer()
            }
            
            Divider()
            
            // Stats Grid
            HStack(spacing: 0) {
                SummaryStatItem(
                    title: "Duration",
                    value: workout.formattedDuration,
                    icon: "clock.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                SummaryStatItem(
                    title: "Volume",
                    value: workout.formattedVolume,
                    icon: "scalemass.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                SummaryStatItem(
                    title: "Sets",
                    value: "\(workout.totalSets)",
                    icon: "number.circle.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                SummaryStatItem(
                    title: "Exercises",
                    value: "\(workout.exerciseCount)",
                    icon: "dumbbell.fill"
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ForEach(sortedExercises) { workoutExercise in
                ExerciseDetailCard(workoutExercise: workoutExercise)
            }
        }
    }
    
    // MARK: - Notes Section
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(notes)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helpers
    private var sortedExercises: [WorkoutExercise] {
        workout.exercises?.sorted { $0.order < $1.order } ?? []
    }
    
    private var formattedDate: String {
        guard let date = workout.completedAt else { return "In Progress" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    private func deleteWorkout() {
        modelContext.delete(workout)
        dismiss()
    }
}

// MARK: - Summary Stat Item
struct SummaryStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let workoutExercise: WorkoutExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if let exercise = workoutExercise.exercise {
                    Image(systemName: exercise.primaryMuscle.icon)
                        .foregroundStyle(.orange)
                    
                    Text(exercise.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Text("\(workoutExercise.sets?.count ?? 0) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Sets Table
            VStack(spacing: 8) {
                // Header
                HStack {
                    Text("SET")
                        .frame(width: 40, alignment: .leading)
                    Text("WEIGHT")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("REPS")
                        .frame(width: 60, alignment: .center)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Divider()
                
                // Sets
                ForEach(Array(workoutExercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                    HStack {
                        Text("\(index + 1)")
                            .frame(width: 40, alignment: .leading)
                            .fontWeight(.medium)
                        
                        Text("\(set.displayWeight) lbs")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(set.reps)")
                            .frame(width: 60, alignment: .center)
                    }
                    .font(.subheadline)
                }
            }
            
            // Volume
            HStack {
                Text("Volume")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f lbs", workoutExercise.volume))
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
            }
            .font(.subheadline)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: Workout(name: "Push Day"))
    }
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
