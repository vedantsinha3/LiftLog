import SwiftUI
import SwiftData

@main
struct LiftLogApp: App {
    @State private var settings = UserSettingsManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            WorkoutTemplate.self,
            TemplateExercise.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
