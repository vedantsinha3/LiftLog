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
    
    // Rest Timer State
    @State private var showingRestTimer = false
    @State private var restTimerDuration: TimeInterval = UserSettingsManager.shared.defaultRestDuration
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
                .background(Color(.systemBackground))
                .navigationTitle(workout.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingDiscardAlert = true
                        } label: {
                            Text("Discard")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingFinishAlert = true
                        } label: {
                            Text("Finish")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(workout.exercises?.isEmpty ?? true ? Color.gray.opacity(0) : Color.black)
                                )
                                .foregroundColor((workout.exercises?.isEmpty ?? true) ? Color.secondary : Color.white)
                        }
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
            
            // Rest Timer Overlay
            if showingRestTimer {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Dismiss on background tap
                        withAnimation(.spring(response: 0.35)) {
                            showingRestTimer = false
                        }
                    }
                
                RestTimerView(
                    isPresented: $showingRestTimer,
                    selectedDuration: $restTimerDuration
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: showingRestTimer)
    }
    
    // MARK: - Timer Header
    private var timerHeader: some View {
        HStack(spacing: 0) {
            // Duration
            VStack(alignment: .leading, spacing: 4) {
                Text("DURATION")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                
                Text(formattedElapsedTime)
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Divider
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1, height: 40)
            
            Spacer()
            
            // Volume
            VStack(alignment: .center, spacing: 4) {
                Text("VOLUME")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                
                Text(workout.formattedVolume)
                    .font(.system(size: 28, weight: .bold))
            }
            
            Spacer()
            
            // Divider
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1, height: 40)
            
            Spacer()
            
            // Sets
            VStack(alignment: .trailing, spacing: 4) {
                Text("SETS")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                
                Text("\(completedSetsCount)/\(workout.totalSets)")
                    .font(.system(size: 28, weight: .bold))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No exercises yet")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Add exercises to start logging your workout")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddExercise = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.headline)
                    Text("Add Exercise")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.black)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Exercise List
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedExercises) { workoutExercise in
                    WorkoutExerciseCard(
                        workoutExercise: workoutExercise,
                        onDelete: { deleteExercise(workoutExercise) },
                        currentWorkout: workout,
                        onSetCompleted: { startRestTimer() }
                    )
                }
                
                // Add Exercise Button
                Button {
                    showingAddExercise = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    )
                    .foregroundStyle(.primary)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(20)
        }
    }
    
    // MARK: - Helpers
    private var sortedExercises: [WorkoutExercise] {
        workout.exercises?.sorted { $0.order < $1.order } ?? []
    }
    
    private var completedSetsCount: Int {
        workout.exercises?.reduce(0) { total, exercise in
            total + (exercise.sets?.filter { $0.isCompleted }.count ?? 0)
        } ?? 0
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
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(exercise)
        }
    }
    
    private func discardWorkout() {
        modelContext.delete(workout)
        isPresented = false
    }
    
    private func finishWorkout() {
        workout.finish()
        isPresented = false
    }
    
    private func startRestTimer() {
        withAnimation(.spring(response: 0.35)) {
            showingRestTimer = true
        }
    }
}

// MARK: - Workout Exercise Card
struct WorkoutExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var workoutExercise: WorkoutExercise
    var onDelete: () -> Void
    var currentWorkout: Workout?
    var onSetCompleted: (() -> Void)?
    
    private var completedCount: Int {
        workoutExercise.sets?.filter { $0.isCompleted }.count ?? 0
    }
    
    private var totalCount: Int {
        workoutExercise.sets?.count ?? 0
    }
    
    private var previousSets: [PreviousSetData] {
        guard let exercise = workoutExercise.exercise else { return [] }
        return ExerciseHistoryService.getPreviousSets(
            for: exercise,
            excludingWorkout: currentWorkout
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                // Exercise Icon
                if let exercise = workoutExercise.exercise {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: exercise.primaryMuscle.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("\(completedCount)/\(totalCount) sets completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(.secondarySystemBackground)))
                }
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.green)
                        .frame(width: totalCount > 0 ? geo.size.width * CGFloat(completedCount) / CGFloat(totalCount) : 0, height: 4)
                        .animation(.spring(response: 0.4), value: completedCount)
                }
            }
            .frame(height: 4)
            
            // Sets Header
            HStack {
                Text("SET")
                    .frame(width: 36, alignment: .leading)
                Text("PREVIOUS")
                    .frame(width: 70, alignment: .leading)
                Spacer()
                Text(UserSettingsManager.shared.weightUnit.rawValue.uppercased())
                    .frame(width: 70, alignment: .center)
                Text("REPS")
                    .frame(width: 56, alignment: .center)
                Spacer()
                    .frame(width: 44)
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.tertiary)
            .tracking(0.5)
            .padding(.top, 4)
            
            // Sets
            VStack(spacing: 8) {
                ForEach(workoutExercise.sortedSets) { set in
                    let setIndex = workoutExercise.sortedSets.firstIndex(where: { $0.id == set.id }) ?? 0
                    let previousData = setIndex < previousSets.count ? previousSets[setIndex] : nil
                    SetRowView(
                        set: set,
                        setNumber: setIndex + 1,
                        previousSetData: previousData,
                        onSetCompleted: onSetCompleted,
                        onDelete: (workoutExercise.sortedSets.count > 1) ? { deleteSet(set) } : nil
                    )
                }
            }
            
            // Add Set Button
            Button {
                addSet()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Add Set")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
                .foregroundStyle(.primary)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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
    
    private func deleteSet(_ set: WorkoutSet) {
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(set)
        }
    }
}

// MARK: - Set Row View
struct SetRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var set: WorkoutSet
    let setNumber: Int
    var previousSetData: PreviousSetData?
    var onSetCompleted: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack(spacing: 8) {
            // Set Number Badge
            ZStack {
                Circle()
                    .fill(set.isCompleted ? Color.green : Color(.tertiarySystemBackground))
                    .frame(width: 28, height: 28)
                
                Text("\(setNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(set.isCompleted ? .white : .primary)
            }
            .frame(width: 36)
            
            // Previous
            Text(previousSetData?.displayString ?? "-")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            // Weight Input
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 70)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(set.isCompleted ? Color(.systemGray5) : Color(.secondarySystemBackground))
                )
                .foregroundStyle(set.isCompleted ? .secondary : .primary)
                .onChange(of: weightText) { _, newValue in
                    set.weight = Double(newValue) ?? 0
                }
                .disabled(set.isCompleted)
            
            // Reps Input
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 56)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(set.isCompleted ? Color(.systemGray5) : Color(.secondarySystemBackground))
                )
                .foregroundStyle(set.isCompleted ? .secondary : .primary)
                .onChange(of: repsText) { _, newValue in
                    set.reps = Int(newValue) ?? 0
                }
                .disabled(set.isCompleted)
            
            // Complete Button
            Button {
                let wasCompleted = set.isCompleted
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    set.isCompleted.toggle()
                    if set.isCompleted {
                        set.completedAt = Date()
                    } else {
                        set.completedAt = nil
                    }
                }
                // Start rest timer when marking set as complete
                if !wasCompleted && set.isCompleted {
                    onSetCompleted?()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(set.isCompleted ? Color.green : Color.clear)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .strokeBorder(set.isCompleted ? Color.clear : Color(.systemGray3), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    if set.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(width: 44)
            
            // Delete Button
            if let onDelete = onDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(.tertiarySystemBackground)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(set.isCompleted ? Color.green.opacity(0.08) : Color.clear)
        )
        .animation(.spring(response: 0.35), value: set.isCompleted)
        .onAppear {
            weightText = set.weight > 0 ? set.displayWeight : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
}

// MARK: - Scale Button Style (shared)
extension View {
    func scaleButtonStyle() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    ActiveWorkoutView(
        workout: Workout(name: "Morning Workout"),
        isPresented: .constant(true)
    )
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
