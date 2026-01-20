import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(
        filter: #Predicate<Workout> { $0.isCompleted == true },
        sort: \Workout.completedAt,
        order: .reverse
    )
    private var workouts: [Workout]
    
    @State private var selectedMonth = Date()
    
    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .navigationTitle("History")
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete your first workout to see it here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Workout List
    private var workoutList: some View {
        List {
            ForEach(groupedWorkouts.keys.sorted().reversed(), id: \.self) { monthKey in
                Section {
                    ForEach(groupedWorkouts[monthKey] ?? []) { workout in
                        NavigationLink {
                            WorkoutDetailView(workout: workout)
                        } label: {
                            WorkoutHistoryRow(workout: workout)
                        }
                    }
                } header: {
                    Text(monthKey)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
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

// MARK: - Workout History Row
struct WorkoutHistoryRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top Row
            HStack {
                Text(workout.name)
                    .font(.headline)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Exercise Names
            if let exercises = workout.exercises, !exercises.isEmpty {
                Text(exerciseNames)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Stats Row
            HStack(spacing: 16) {
                StatBadge(icon: "clock", value: workout.formattedDuration)
                StatBadge(icon: "scalemass", value: workout.formattedVolume)
                StatBadge(icon: "number", value: "\(workout.totalSets) sets")
            }
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        guard let date = workout.completedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var exerciseNames: String {
        guard let exercises = workout.exercises else { return "" }
        return exercises
            .sorted { $0.order < $1.order }
            .compactMap { $0.exercise?.name }
            .joined(separator: ", ")
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    HistoryListView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
