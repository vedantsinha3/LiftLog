import Foundation
import SwiftData

// MARK: - Workout Template Model
@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var notes: String?
    var createdAt: Date
    var lastUsedAt: Date?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]?
    
    // Computed Properties
    var exerciseCount: Int {
        exercises?.count ?? 0
    }
    
    var sortedExercises: [TemplateExercise] {
        exercises?.sorted { $0.order < $1.order } ?? []
    }
    
    var totalSets: Int {
        exercises?.reduce(0) { $0 + $1.defaultSetCount } ?? 0
    }
    
    var muscleGroupsSummary: String {
        let muscles = exercises?.compactMap { $0.exercise?.primaryMuscle.rawValue } ?? []
        let uniqueMuscles = Array(Set(muscles))
        if uniqueMuscles.isEmpty {
            return "No exercises"
        }
        if uniqueMuscles.count <= 2 {
            return uniqueMuscles.joined(separator: ", ")
        }
        return "\(uniqueMuscles[0]), \(uniqueMuscles[1]) +\(uniqueMuscles.count - 2)"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

// MARK: - Template Exercise Model
@Model
final class TemplateExercise {
    var id: UUID
    var order: Int
    var defaultSetCount: Int
    var defaultWeight: Double?
    var defaultReps: Int?
    var notes: String?
    
    // Relationships
    var template: WorkoutTemplate?
    var exercise: Exercise?
    
    init(
        id: UUID = UUID(),
        order: Int = 0,
        defaultSetCount: Int = 3,
        defaultWeight: Double? = nil,
        defaultReps: Int? = nil,
        notes: String? = nil,
        template: WorkoutTemplate? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.defaultSetCount = defaultSetCount
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
        self.notes = notes
        self.template = template
        self.exercise = exercise
    }
}
