import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    
    @State private var showingDeleteAlert = false
    @State private var showingEditWorkout = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Summary Card
                summaryCard
                
                // Exercises
                exercisesSection
                
                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditWorkout = true
                    } label: {
                        Label("Edit Workout", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(.secondarySystemBackground)))
                }
            }
        }
        .sheet(isPresented: $showingEditWorkout) {
            EditWorkoutView(workout: workout)
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
        VStack(spacing: 20) {
            // Date Header
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Stats Grid
            HStack(spacing: 12) {
                SummaryStatCard(
                    title: "Duration",
                    value: workout.formattedDuration,
                    icon: "clock.fill",
                    gradient: [.blue, .cyan]
                )
                
                SummaryStatCard(
                    title: "Volume",
                    value: workout.formattedVolume,
                    icon: "scalemass.fill",
                    gradient: [.orange, .red]
                )
            }
            
            HStack(spacing: 12) {
                SummaryStatCard(
                    title: "Total Sets",
                    value: "\(workout.totalSets)",
                    icon: "number.circle.fill",
                    gradient: [.purple, .pink]
                )
                
                SummaryStatCard(
                    title: "Exercises",
                    value: "\(workout.exerciseCount)",
                    icon: "dumbbell.fill",
                    gradient: [.green, .mint]
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Exercises")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(sortedExercises) { workoutExercise in
                    ExerciseDetailCard(workoutExercise: workoutExercise)
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Notes")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(notes)
                .font(.body)
                .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Helpers
    private var sortedExercises: [WorkoutExercise] {
        workout.exercises?.sorted { $0.order < $1.order } ?? []
    }
    
    private var formattedDate: String {
        guard let date = workout.completedAt else { return "In Progress" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    private func deleteWorkout() {
        modelContext.delete(workout)
        dismiss()
    }
}

// MARK: - Summary Stat Card
struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(gradient.first ?? .gray)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let workoutExercise: WorkoutExercise
    
    @State private var isExpanded = true
    
    private var totalVolume: String {
        let settings = UserSettingsManager.shared
        let volume = workoutExercise.volume * settings.weightUnit.fromLbsFactor
        if volume >= 1000 {
            return String(format: "%.1fk %@", volume / 1000, settings.weightUnit.rawValue)
        }
        return String(format: "%.0f %@", volume, settings.weightUnit.rawValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            Button {
                withAnimation(.spring(response: 0.35)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Exercise Icon
                    if let exercise = workoutExercise.exercise {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: exercise.primaryMuscle.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text("\(workoutExercise.sets?.count ?? 0) sets • \(totalVolume)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                // Sets Table
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("SET")
                            .frame(width: 40, alignment: .leading)
                        Text("WEIGHT")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("REPS")
                            .frame(width: 60, alignment: .center)
                        Text("VOLUME")
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .tracking(0.5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.quaternarySystemFill))
                    
                    // Sets
                    ForEach(Array(workoutExercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            // Set Number
                            ZStack {
                                Circle()
                                    .fill(Color(.tertiarySystemBackground))
                                    .frame(width: 26, height: 26)
                                
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .frame(width: 40, alignment: .leading)
                            
                            // Weight
                            Text(UserSettingsManager.shared.formatWeightWithUnit(set.weight))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            // Reps
                            Text("\(set.reps)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 60, alignment: .center)
                            
                            // Volume
                            Text(String(format: "%.0f", set.volume))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        
                        if index < workoutExercise.sortedSets.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: Workout(name: "Push Day"))
    }
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
