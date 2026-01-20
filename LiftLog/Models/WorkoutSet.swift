import Foundation
import SwiftData

// MARK: - Set Type Enum
enum SetType: String, Codable, CaseIterable, Identifiable {
    case warmup = "Warm-up"
    case working = "Working"
    case dropSet = "Drop Set"
    case failure = "Failure"
    
    var id: String { rawValue }
    
    var shortLabel: String {
        switch self {
        case .warmup: return "W"
        case .working: return ""
        case .dropSet: return "D"
        case .failure: return "F"
        }
    }
    
    var color: String {
        switch self {
        case .warmup: return "yellow"
        case .working: return "primary"
        case .dropSet: return "purple"
        case .failure: return "red"
        }
    }
}

// MARK: - Workout Set Model
@Model
final class WorkoutSet {
    var id: UUID
    var order: Int
    var weight: Double
    var reps: Int
    var rpe: Int?
    var setType: SetType
    var isCompleted: Bool
    var completedAt: Date?
    var isPR: Bool
    
    // Relationship
    var workoutExercise: WorkoutExercise?
    
    // Computed Properties
    var volume: Double {
        weight * Double(reps)
    }
    
    /// Estimated 1RM using Brzycki formula
    var estimated1RM: Double {
        guard reps > 0 && reps <= 12 else { return weight }
        if reps == 1 { return weight }
        return weight * (36 / (37 - Double(reps)))
    }
    
    var displayWeight: String {
        if weight == floor(weight) {
            return String(format: "%.0f", weight)
        }
        return String(format: "%.1f", weight)
    }
    
    init(
        id: UUID = UUID(),
        order: Int = 0,
        weight: Double = 0,
        reps: Int = 0,
        rpe: Int? = nil,
        setType: SetType = .working,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isPR: Bool = false
    ) {
        self.id = id
        self.order = order
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.setType = setType
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isPR = isPR
    }
    
    func complete() {
        self.isCompleted = true
        self.completedAt = Date()
    }
}
