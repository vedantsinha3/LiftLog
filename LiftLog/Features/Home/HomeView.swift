import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Workout> { $0.isCompleted == true }, sort: \Workout.completedAt, order: .reverse)
    private var recentWorkouts: [Workout]
    
    @Binding var showingActiveWorkout: Bool
    @Binding var activeWorkout: Workout?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection
                    
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
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange.gradient)
            
            Text("Ready to lift?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button(action: startNewWorkout) {
                Label("Start Workout", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

#Preview {
    HomeView(showingActiveWorkout: .constant(false), activeWorkout: .constant(nil))
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
