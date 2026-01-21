import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(
        filter: #Predicate<Workout> { $0.isCompleted == true },
        sort: \Workout.completedAt,
        order: .reverse
    )
    private var workouts: [Workout]
    
    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("History")
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No Workouts Yet")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Complete your first workout to see it here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Workout List
    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(groupedWorkouts.keys.sorted().reversed(), id: \.self) { monthKey in
                    VStack(alignment: .leading, spacing: 12) {
                        // Month Header
                        HStack {
                            Text(monthKey)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("\(groupedWorkouts[monthKey]?.count ?? 0) workouts")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(.tertiarySystemBackground)))
                        }
                        .padding(.horizontal, 4)
                        
                        // Workouts
                        VStack(spacing: 10) {
                            ForEach(groupedWorkouts[monthKey] ?? []) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutHistoryCard(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Grouped Workouts
    private var groupedWorkouts: [String: [Workout]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        var groups: [String: [Workout]] = [:]
        
        for workout in workouts {
            let key = formatter.string(from: workout.completedAt ?? workout.startedAt)
            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(workout)
        }
        
        return groups
    }
}

// MARK: - Workout History Card
struct WorkoutHistoryCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(Color.black)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            
            // Exercise Names
            if let exercises = workout.exercises, !exercises.isEmpty {
                Text(exerciseNames)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Stats Row
            HStack(spacing: 0) {
                StatPill(icon: "clock.fill", value: workout.formattedDuration)
                
                Spacer()
                
                StatPill(icon: "scalemass.fill", value: workout.formattedVolume)
                
                Spacer()
                
                StatPill(icon: "number", value: "\(workout.totalSets) sets")
                
                Spacer()
                
                StatPill(icon: "figure.strengthtraining.traditional", value: "\(workout.exerciseCount)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var formattedDate: String {
        guard let date = workout.completedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private var exerciseNames: String {
        guard let exercises = workout.exercises else { return "" }
        return exercises
            .sorted { $0.order < $1.order }
            .compactMap { $0.exercise?.name }
            .joined(separator: " • ")
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

#Preview {
    HistoryListView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
