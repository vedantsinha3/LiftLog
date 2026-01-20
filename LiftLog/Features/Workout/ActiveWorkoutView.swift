import SwiftUI
import SwiftData
internal import Combine

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var workout: Workout
    @Binding var isPresented: Bool
    
    @State private var showingAddExercise = false
    @State private var showingDiscardAlert = false
    @State private var showingFinishAlert = false
    @State private var workoutStartTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timer Header
                timerHeader
                
                // Exercise List
                if workout.exercises?.isEmpty ?? true {
                    emptyState
                } else {
                    exerciseList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Discard") {
                        showingDiscardAlert = true
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") {
                        showingFinishAlert = true
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    .disabled(workout.exercises?.isEmpty ?? true)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                ExercisePickerView(workout: workout)
            }
            .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    discardWorkout()
                }
            } message: {
                Text("This will delete all logged sets from this workout.")
            }
            .alert("Finish Workout?", isPresented: $showingFinishAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Finish") {
                    finishWorkout()
                }
            } message: {
                Text("Complete this workout with \(workout.totalSets) sets logged.")
            }
            .onReceive(timer) { _ in
                elapsedTime = Date().timeIntervalSince(workoutStartTime)
            }
            .onAppear {
                workoutStartTime = workout.startedAt
            }
        }
    }
    
    // MARK: - Timer Header
    private var timerHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Duration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formattedElapsedTime)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Volume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(workout.formattedVolume)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "dumbbell")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No exercises yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Add exercises to start logging your workout")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                showingAddExercise = true
            } label: {
                Label("Add Exercise", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Exercise List
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedExercises) { workoutExercise in
                    WorkoutExerciseCard(
                        workoutExercise: workoutExercise,
                        onDelete: { deleteExercise(workoutExercise) }
                    )
                }
                
                // Add Exercise Button
                Button {
                    showingAddExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
    
    // MARK: - Helpers
    private var sortedExercises: [WorkoutExercise] {
        workout.exercises?.sorted { $0.order < $1.order } ?? []
    }
    
    private var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    private func deleteExercise(_ exercise: WorkoutExercise) {
        modelContext.delete(exercise)
    }
    
    private func discardWorkout() {
        modelContext.delete(workout)
        isPresented = false
    }
    
    private func finishWorkout() {
        workout.finish()
        isPresented = false
    }
}

// MARK: - Workout Exercise Card
struct WorkoutExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var workoutExercise: WorkoutExercise
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if let exercise = workoutExercise.exercise {
                    Image(systemName: exercise.primaryMuscle.icon)
                        .foregroundStyle(.orange)
                    Text(exercise.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Remove Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
            
            // Sets Header
            HStack {
                Text("SET")
                    .frame(width: 40, alignment: .leading)
                Text("PREVIOUS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("LBS")
                    .frame(width: 70, alignment: .center)
                Text("REPS")
                    .frame(width: 60, alignment: .center)
                Spacer()
                    .frame(width: 44)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            // Sets
            ForEach(workoutExercise.sortedSets) { set in
                SetRowView(set: set, setNumber: (workoutExercise.sortedSets.firstIndex(where: { $0.id == set.id }) ?? 0) + 1)
            }
            
            // Add Set Button
            Button {
                addSet()
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func addSet() {
        let newSet = WorkoutSet(
            order: workoutExercise.sets?.count ?? 0,
            weight: 0,
            reps: 0
        )
        newSet.workoutExercise = workoutExercise
        modelContext.insert(newSet)
    }
}

// MARK: - Set Row View
struct SetRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var set: WorkoutSet
    let setNumber: Int
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack {
            // Set Number
            Text("\(setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .leading)
                .foregroundStyle(set.isCompleted ? .orange : .primary)
            
            // Previous (placeholder)
            Text("-")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Weight Input
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: weightText) { _, newValue in
                    set.weight = Double(newValue) ?? 0
                }
            
            // Reps Input
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: repsText) { _, newValue in
                    set.reps = Int(newValue) ?? 0
                }
            
            // Complete Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    set.isCompleted.toggle()
                    if set.isCompleted {
                        set.completedAt = Date()
                    } else {
                        set.completedAt = nil
                    }
                }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 44)
        }
        .onAppear {
            weightText = set.weight > 0 ? set.displayWeight : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
}

#Preview {
    ActiveWorkoutView(
        workout: Workout(name: "Morning Workout"),
        isPresented: .constant(true)
    )
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
