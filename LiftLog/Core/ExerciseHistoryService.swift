import Foundation
import SwiftData

/// Represents a previous set's performance data
struct PreviousSetData {
    let weight: Double
    let reps: Int
    let completedAt: Date?
    
    var displayString: String {
        let weightStr = weight == floor(weight) ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
        return "\(weightStr) × \(reps)"
    }
}

/// Represents a single data point for exercise progression chart
struct ExerciseProgressionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let totalSets: Int
    let totalReps: Int
}

/// Service for querying exercise history and previous performance data
struct ExerciseHistoryService {
    
    /// Fetches the previous workout's sets for a given exercise
    /// - Parameters:
    ///   - exercise: The exercise to look up history for
    ///   - excludingWorkout: Optional workout to exclude (usually the current active workout)
    /// - Returns: Array of PreviousSetData sorted by set order, or empty array if no history
    static func getPreviousSets(
        for exercise: Exercise,
        excludingWorkout: Workout? = nil
    ) -> [PreviousSetData] {
        // Get all workout exercises for this exercise
        guard let workoutExercises = exercise.workoutExercises else {
            return []
        }
        
        // Filter to completed workouts only, excluding current workout if provided
        let completedWorkoutExercises = workoutExercises.filter { workoutExercise in
            guard let workout = workoutExercise.workout else { return false }
            
            // Must be completed
            guard workout.isCompleted else { return false }
            
            // Exclude the current workout if provided
            if let excludedWorkout = excludingWorkout {
                if workout.id == excludedWorkout.id {
                    return false
                }
            }
            
            return true
        }
        
        // Sort by workout completion date (most recent first)
        let sortedWorkoutExercises = completedWorkoutExercises.sorted { we1, we2 in
            let date1 = we1.workout?.completedAt ?? we1.workout?.startedAt ?? Date.distantPast
            let date2 = we2.workout?.completedAt ?? we2.workout?.startedAt ?? Date.distantPast
            return date1 > date2
        }
        
        // Get the most recent workout exercise
        guard let mostRecentWorkoutExercise = sortedWorkoutExercises.first else {
            return []
        }
        
        // Get and sort the sets
        let sortedSets = mostRecentWorkoutExercise.sortedSets
        
        // Convert to PreviousSetData
        return sortedSets.map { set in
            PreviousSetData(
                weight: set.weight,
                reps: set.reps,
                completedAt: set.completedAt
            )
        }
    }
    
    /// Gets the date of the last time this exercise was performed
    /// - Parameter exercise: The exercise to check
    /// - Returns: The completion date of the most recent workout containing this exercise, or nil
    static func getLastPerformedDate(for exercise: Exercise) -> Date? {
        guard let workoutExercises = exercise.workoutExercises else {
            return nil
        }
        
        let completedWorkoutExercises = workoutExercises.filter { workoutExercise in
            workoutExercise.workout?.isCompleted ?? false
        }
        
        let sortedWorkoutExercises = completedWorkoutExercises.sorted { we1, we2 in
            let date1 = we1.workout?.completedAt ?? Date.distantPast
            let date2 = we2.workout?.completedAt ?? Date.distantPast
            return date1 > date2
        }
        
        return sortedWorkoutExercises.first?.workout?.completedAt
    }
    
    /// Gets progression data for an exercise (max weight per workout over time)
    /// - Parameter exercise: The exercise to get progression for
    /// - Returns: Array of ExerciseProgressionPoint sorted by date (oldest first)
    static func getProgressionData(for exercise: Exercise) -> [ExerciseProgressionPoint] {
        guard let workoutExercises = exercise.workoutExercises else {
            return []
        }
        
        // Filter to completed workouts only
        let completedWorkoutExercises = workoutExercises.filter { workoutExercise in
            guard let workout = workoutExercise.workout else { return false }
            return workout.isCompleted
        }
        
        // Map each workout exercise to a progression point
        var progressionPoints: [ExerciseProgressionPoint] = []
        
        for workoutExercise in completedWorkoutExercises {
            guard let workout = workoutExercise.workout,
                  let completedAt = workout.completedAt,
                  let sets = workoutExercise.sets,
                  !sets.isEmpty else {
                continue
            }
            
            // Find the max weight from all completed sets
            let completedSets = sets.filter { $0.isCompleted && $0.weight > 0 }
            guard !completedSets.isEmpty else { continue }
            
            let maxWeight = completedSets.map { $0.weight }.max() ?? 0
            let totalSets = completedSets.count
            let totalReps = completedSets.reduce(0) { $0 + $1.reps }
            
            progressionPoints.append(ExerciseProgressionPoint(
                date: completedAt,
                maxWeight: maxWeight,
                totalSets: totalSets,
                totalReps: totalReps
            ))
        }
        
        // Sort by date (oldest first for chart display)
        return progressionPoints.sorted { $0.date < $1.date }
    }
    
    /// Gets the personal best (max weight ever lifted) for an exercise
    /// - Parameter exercise: The exercise to check
    /// - Returns: The maximum weight ever lifted, or nil if no history
    static func getPersonalBest(for exercise: Exercise) -> Double? {
        let progression = getProgressionData(for: exercise)
        return progression.map { $0.maxWeight }.max()
    }
}
