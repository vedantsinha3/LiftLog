import Foundation
import SwiftData

/// Loads pre-populated exercise data from JSON into the database
struct ExerciseDataLoader {
    
    /// Loads exercises from JSON file if database is empty
    static func loadExercisesIfNeeded(modelContext: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else {
            print("✅ Exercises already loaded: \(existingCount) exercises")
            return
        }
        
        // Load from JSON
        guard let url = Bundle.main.url(forResource: "ExerciseData", withExtension: "json") else {
            print("❌ ExerciseData.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let exerciseDataList = try decoder.decode([ExerciseData].self, from: data)
            
            for exerciseData in exerciseDataList {
                let exercise = exerciseData.toExercise()
                modelContext.insert(exercise)
            }
            
            try modelContext.save()
            print("✅ Loaded \(exerciseDataList.count) exercises from JSON")
            
        } catch {
            print("❌ Failed to load exercises: \(error)")
        }
    }
    
    /// Creates a sample exercise for previews
    static func sampleExercise() -> Exercise {
        Exercise(
            name: "Barbell Bench Press",
            primaryMuscle: .chest,
            secondaryMuscles: [.triceps, .shoulders],
            equipment: .barbell,
            instructions: "Lie on a flat bench, grip the bar slightly wider than shoulder-width, lower to chest, press up."
        )
    }
    
    /// Creates sample exercises for previews
    static func sampleExercises() -> [Exercise] {
        [
            Exercise(name: "Barbell Bench Press", primaryMuscle: .chest, secondaryMuscles: [.triceps, .shoulders], equipment: .barbell),
            Exercise(name: "Dumbbell Row", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .dumbbell),
            Exercise(name: "Barbell Squat", primaryMuscle: .quads, secondaryMuscles: [.glutes, .hamstrings], equipment: .barbell),
            Exercise(name: "Overhead Press", primaryMuscle: .shoulders, secondaryMuscles: [.triceps], equipment: .barbell),
            Exercise(name: "Pull-Up", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .bodyweight),
            Exercise(name: "Romanian Deadlift", primaryMuscle: .hamstrings, secondaryMuscles: [.back, .glutes], equipment: .barbell)
        ]
    }
}
