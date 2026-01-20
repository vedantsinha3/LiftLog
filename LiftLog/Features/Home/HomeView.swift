import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Workout> { $0.isCompleted == true }, sort: \Workout.completedAt, order: .reverse)
    private var recentWorkouts: [Workout]
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse)
    private var templates: [WorkoutTemplate]
    
    @Binding var showingActiveWorkout: Bool
    @Binding var activeWorkout: Workout?
    
    @State private var showingTemplateSelection = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection
                    
                    // Quick Start from Template
                    if !templates.isEmpty {
                        quickStartSection
                    }
                    
                    // Quick Stats
                    if !recentWorkouts.isEmpty {
                        quickStatsSection
                    }
                    
                    // Recent Workouts
                    if !recentWorkouts.isEmpty {
                        recentWorkoutsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("LiftLog")
            .onAppear {
                ExerciseDataLoader.loadExercisesIfNeeded(modelContext: modelContext)
            }
            .sheet(isPresented: $showingTemplateSelection) {
                TemplateSelectionSheet(
                    templates: templates,
                    onSelectTemplate: startWorkoutFromTemplate
                )
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(.black)
            
            Text("Ready to lift?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button(action: startNewWorkout) {
                Label("Start Workout", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.black.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Start")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if templates.count > 3 {
                    Button("See All") {
                        showingTemplateSelection = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(templates.prefix(5)) { template in
                        QuickStartTemplateCard(template: template) {
                            startWorkoutFromTemplate(template)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Workouts",
                    value: "\(workoutsThisWeek)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Volume",
                    value: volumeThisWeek,
                    icon: "scalemass.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Streak",
                    value: "\(currentStreak)",
                    icon: "bolt.fill",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Recent Workouts
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ForEach(recentWorkouts.prefix(3)) { workout in
                RecentWorkoutCard(workout: workout)
            }
        }
    }
    
    // MARK: - Actions
    private func startNewWorkout() {
        let workout = Workout(name: "Workout")
        modelContext.insert(workout)
        activeWorkout = workout
        showingActiveWorkout = true
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        // Create a new workout from the template
        let workout = Workout(name: template.name)
        modelContext.insert(workout)
        
        // Copy exercises from template
        for templateExercise in template.sortedExercises {
            let workoutExercise = WorkoutExercise(
                order: templateExercise.order,
                workout: workout,
                exercise: templateExercise.exercise
            )
            modelContext.insert(workoutExercise)
            
            // Create default sets
            for setIndex in 0..<templateExercise.defaultSetCount {
                let set = WorkoutSet(
                    order: setIndex,
                    weight: templateExercise.defaultWeight ?? 0,
                    reps: templateExercise.defaultReps ?? 0
                )
                set.workoutExercise = workoutExercise
                modelContext.insert(set)
            }
        }
        
        // Update template's last used date
        template.lastUsedAt = Date()
        
        activeWorkout = workout
        showingActiveWorkout = true
    }
    
    // MARK: - Computed Properties
    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return recentWorkouts.filter { ($0.completedAt ?? Date()) >= startOfWeek }.count
    }
    
    private var volumeThisWeek: String {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let total = recentWorkouts
            .filter { ($0.completedAt ?? Date()) >= startOfWeek }
            .reduce(0) { $0 + $1.totalVolume }
        
        if total >= 1000 {
            return String(format: "%.1fk", total / 1000)
        }
        return String(format: "%.0f", total)
    }
    
    private var currentStreak: Int {
        // Simple streak calculation - count consecutive weeks with workouts
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        
        for _ in 0..<52 {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: checkDate)) ?? checkDate
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? checkDate
            
            let hasWorkout = recentWorkouts.contains { workout in
                guard let completed = workout.completedAt else { return false }
                return completed >= weekStart && completed < weekEnd
            }
            
            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -7, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Recent Workout Card
struct RecentWorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(workout.formattedDuration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(workout.formattedVolume)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var formattedDate: String {
        guard let date = workout.completedAt else { return "In Progress" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Quick Start Template Card
struct QuickStartTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(template.muscleGroupsSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption2)
                    Text("\(template.exerciseCount)")
                        .font(.caption2)
                    
                    Spacer()
                    
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(width: 140, height: 100)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Selection Sheet
struct TemplateSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templates: [WorkoutTemplate]
    let onSelectTemplate: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            List(templates) { template in
                Button {
                    onSelectTemplate(template)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(template.muscleGroupsSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("\(template.exerciseCount) exercises • \(template.totalSets) sets")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Start from Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(showingActiveWorkout: .constant(false), activeWorkout: .constant(nil))
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
