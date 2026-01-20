import Foundation
import SwiftData

// MARK: - Muscle Group Enum
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case core = "Core"
    case fullBody = "Full Body"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.boxing"
        case .biceps: return "figure.strengthtraining.traditional"
        case .triceps: return "figure.strengthtraining.functional"
        case .quads: return "figure.run"
        case .hamstrings: return "figure.cooldown"
        case .glutes: return "figure.hiking"
        case .calves: return "figure.stairs"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}

// MARK: - Equipment Enum
enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case cable = "Cable"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .barbell: return "line.horizontal.3"
        case .dumbbell: return "dumbbell.fill"
        case .cable: return "arrow.up.and.down"
        case .machine: return "gearshape.fill"
        case .bodyweight: return "figure.stand"
        case .kettlebell: return "circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Exercise Model
@Model
final class Exercise {
    var id: UUID
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: Equipment
    var instructions: String?
    var isCustom: Bool
    var createdAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise]?
    
    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        equipment: Equipment,
        instructions: String? = nil,
        isCustom: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.instructions = instructions
        self.isCustom = isCustom
        self.createdAt = createdAt
    }
}

// MARK: - Exercise Data Structure (for JSON import)
struct ExerciseData: Codable {
    let name: String
    let primaryMuscle: String
    let secondaryMuscles: [String]
    let equipment: String
    let instructions: String?
    
    func toExercise() -> Exercise {
        Exercise(
            name: name,
            primaryMuscle: MuscleGroup(rawValue: primaryMuscle) ?? .fullBody,
            secondaryMuscles: secondaryMuscles.compactMap { MuscleGroup(rawValue: $0) },
            equipment: Equipment(rawValue: equipment) ?? .other,
            instructions: instructions,
            isCustom: false
        )
    }
}
