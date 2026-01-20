import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingActiveWorkout = false
    @State private var activeWorkout: Workout?

    var body: some View {
        TabView {
            HomeView(showingActiveWorkout: $showingActiveWorkout,
                     activeWorkout: $activeWorkout)
            .tabItem { Label("Home", systemImage: "house.fill") }

            TemplatesListView()
                .tabItem { Label("Templates", systemImage: "doc.on.doc.fill") }

            ExerciseListView()
                .tabItem { Label("Exercises", systemImage: "dumbbell.fill") }

            HistoryListView()
                .tabItem { Label("History", systemImage: "clock.fill") }
        }
        .tint(.primary)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .fullScreenCover(item: $activeWorkout, onDismiss: {
            showingActiveWorkout = false
        }) { workout in
            ActiveWorkoutView(workout: workout, isPresented: Binding(
                get: { activeWorkout != nil },
                set: { if !$0 { activeWorkout = nil } }
            ))
        }
    }
}
// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("doc.on.doc.fill", "Templates"),
        ("dumbbell.fill", "Exercises"),
        ("clock.fill", "History")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabBarButton(
                    icon: tabs[index].icon,
                    label: tabs[index].label,
                    isSelected: selectedTab == index,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            TabBarBackground()
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon with background pill
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 56, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
                .frame(height: 32)
                
                // Label
                Text(label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Bar Background
struct TabBarBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1),
                alignment: .top
            )
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -8)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
