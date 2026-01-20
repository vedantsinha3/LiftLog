import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingActiveWorkout = false
    @State private var activeWorkout: Workout?
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(
                    showingActiveWorkout: $showingActiveWorkout,
                    activeWorkout: $activeWorkout
                )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                
                TemplatesListView()
                    .tabItem {
                        Label("Templates", systemImage: "doc.on.doc.fill")
                    }
                    .tag(1)
                
                ExerciseListView()
                    .tabItem {
                        Label("Exercises", systemImage: "dumbbell.fill")
                    }
                    .tag(2)
                
                HistoryListView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                    .tag(3)
            }
            .tint(.orange)
        }
        .fullScreenCover(
            isPresented: $showingActiveWorkout,
            onDismiss: {
                activeWorkout = nil
                selectedTab = 0   // <- this returns to Home tab
            }
        ) {
            if let workout = activeWorkout {
                ActiveWorkoutView(workout: workout, isPresented: $showingActiveWorkout)
            } else {
                // defensive fallback so you never get a blank white screen
                ProgressView("Starting workout…")
                    .onAppear { showingActiveWorkout = false }
            }
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
