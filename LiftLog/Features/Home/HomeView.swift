import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Workout> { $0.isCompleted == true }, sort: \Workout.completedAt, order: .reverse)
    private var recentWorkouts: [Workout]
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse)
    private var templates: [WorkoutTemplate]
    
    @Binding var showingActiveWorkout: Bool
    @Binding var activeWorkout: Workout?
    
    @State private var showingTemplateSelection = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero Section
                    heroSection
                    
                    // Quick Start from Template
                    if !templates.isEmpty {
                        quickStartSection
                    }
                    
                    // Quick Stats
                    if !recentWorkouts.isEmpty {
                        quickStatsSection
                    }
                    
                    // Recent Workouts
                    if !recentWorkouts.isEmpty {
                        recentWorkoutsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        
                        Text("LiftLog")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                    }
                }
            }
            .onAppear {
                ExerciseDataLoader.loadExercisesIfNeeded(modelContext: modelContext)
            }
            .sheet(isPresented: $showingTemplateSelection) {
                TemplateSelectionSheet(
                    templates: templates,
                    onSelectTemplate: startWorkoutFromTemplate
                )
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Greeting
            VStack(spacing: 6) {
                Text(greetingText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                
                Text("Ready to lift?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            
            // Start Button
            Button(action: startNewWorkout) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.title3)
                    
                    Text("Start Empty Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Quick Start")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if templates.count > 3 {
                    Button {
                        showingTemplateSelection = true
                    } label: {
                        Text("See All")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary.opacity(0.6))
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(templates.prefix(5)) { template in
                        QuickStartTemplateCard(template: template) {
                            startWorkoutFromTemplate(template)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Workouts",
                    value: "\(workoutsThisWeek)",
                    icon: "flame.fill",
                    gradient: [Color.orange, Color.red]
                )
                
                StatCard(
                    title: "Volume",
                    value: volumeThisWeek,
                    icon: "scalemass.fill",
                    gradient: [Color.blue, Color.cyan]
                )
                
                StatCard(
                    title: "Streak",
                    value: "\(currentStreak)w",
                    icon: "bolt.fill",
                    gradient: [Color.yellow, Color.orange]
                )
            }
        }
    }
    
    // MARK: - Recent Workouts
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                ForEach(recentWorkouts.prefix(3)) { workout in
                    RecentWorkoutCard(workout: workout)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Late Night"
        }
    }
    
    // MARK: - Actions
    private func startNewWorkout() {
        let workout = Workout(name: "Workout")
        modelContext.insert(workout)
        activeWorkout = workout
        showingActiveWorkout = true
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let workout = Workout(name: template.name)
        modelContext.insert(workout)
        
        for templateExercise in template.sortedExercises {
            let workoutExercise = WorkoutExercise(
                order: templateExercise.order,
                workout: workout,
                exercise: templateExercise.exercise
            )
            modelContext.insert(workoutExercise)
            
            for setIndex in 0..<templateExercise.defaultSetCount {
                let set = WorkoutSet(
                    order: setIndex,
                    weight: templateExercise.defaultWeight ?? 0,
                    reps: templateExercise.defaultReps ?? 0
                )
                set.workoutExercise = workoutExercise
                modelContext.insert(set)
            }
        }
        
        template.lastUsedAt = Date()
        activeWorkout = workout
        showingActiveWorkout = true
    }
    
    // MARK: - Computed Properties
    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return recentWorkouts.filter { ($0.completedAt ?? Date()) >= startOfWeek }.count
    }
    
    private var volumeThisWeek: String {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let total = recentWorkouts
            .filter { ($0.completedAt ?? Date()) >= startOfWeek }
            .reduce(0) { $0 + $1.totalVolume }
        
        if total >= 1000 {
            return String(format: "%.1fk", total / 1000)
        }
        return String(format: "%.0f", total)
    }
    
    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        
        for _ in 0..<52 {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: checkDate)) ?? checkDate
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? checkDate
            
            let hasWorkout = recentWorkouts.contains { workout in
                guard let completed = workout.completedAt else { return false }
                return completed >= weekStart && completed < weekEnd
            }
            
            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -7, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Recent Workout Card
struct RecentWorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.8), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(workout.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(workout.formattedVolume)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
    
    private var formattedDate: String {
        guard let date = workout.completedAt else { return "In Progress" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Quick Start Template Card
struct QuickStartTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                Text(template.muscleGroupsSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption2)
                        Text("\(template.exerciseCount)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.primary)
                }
            }
            .padding(14)
            .frame(width: 150, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Template Selection Sheet
struct TemplateSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templates: [WorkoutTemplate]
    let onSelectTemplate: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(templates) { template in
                        Button {
                            onSelectTemplate(template)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.black.opacity(0.8), Color.black],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("\(template.exerciseCount) exercises • \(template.totalSets) sets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.primary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Start from Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

#Preview {
    HomeView(showingActiveWorkout: .constant(false), activeWorkout: .constant(nil))
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
