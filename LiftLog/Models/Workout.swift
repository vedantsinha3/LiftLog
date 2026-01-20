import Foundation
import SwiftData

// MARK: - Workout Model
@Model
final class Workout {
    var id: UUID
    var name: String
    var startedAt: Date
    var completedAt: Date?
    var notes: String?
    var isCompleted: Bool
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]?
    
    // Computed Properties
    var duration: TimeInterval? {
        guard let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "In Progress" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
    
    var totalVolume: Double {
        exercises?.reduce(0) { total, exercise in
            total + exercise.volume
        } ?? 0
    }
    
    var formattedVolume: String {
        let volume = totalVolume
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }
    
    var totalSets: Int {
        exercises?.reduce(0) { total, exercise in
            total + (exercise.sets?.count ?? 0)
        } ?? 0
    }
    
    var exerciseCount: Int {
        exercises?.count ?? 0
    }
    
    init(
        id: UUID = UUID(),
        name: String = "Workout",
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        notes: String? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.notes = notes
        self.isCompleted = isCompleted
    }
    
    func finish() {
        self.completedAt = Date()
        self.isCompleted = true
    }
}

// MARK: - Workout Exercise (Junction table)
@Model
final class WorkoutExercise {
    var id: UUID
    var order: Int
    
    // Relationships
    var workout: Workout?
    var exercise: Exercise?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet]?
    
    // Computed Properties
    var volume: Double {
        sets?.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        } ?? 0
    }
    
    var sortedSets: [WorkoutSet] {
        sets?.sorted { $0.order < $1.order } ?? []
    }
    
    init(
        id: UUID = UUID(),
        order: Int = 0,
        workout: Workout? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.workout = workout
        self.exercise = exercise
    }
}
