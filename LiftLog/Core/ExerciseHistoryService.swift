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
}
