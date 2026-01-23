import SwiftUI
import AVFoundation

// MARK: - Floating Rest Timer
struct FloatingRestTimer: View {
    @Binding var isActive: Bool
    @Binding var selectedDuration: TimeInterval
    
    @State private var remainingTime: TimeInterval
    @State private var isRunning = true
    @State private var isExpanded = false
    @State private var timer: Timer?
    
    let presetDurations: [TimeInterval] = [30, 60, 90, 120, 180, 300]
    
    init(isActive: Binding<Bool>, selectedDuration: Binding<TimeInterval>) {
        self._isActive = isActive
        self._selectedDuration = selectedDuration
        self._remainingTime = State(initialValue: selectedDuration.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
            } else {
                miniView
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Mini View (Floating Pill)
    private var miniView: some View {
        HStack(spacing: 12) {
            // Progress ring (mini)
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timerColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
            }
            
            // Time display
            Text(formattedTime)
                .font(.system(size: 20, weight: .bold))
                .monospacedDigit()
            
            // Pause/Play button
            Button {
                toggleTimer()
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            
            // Skip button
            Button {
                skip()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(.tertiarySystemBackground)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.35)) {
                isExpanded = true
            }
        }
    }
    
    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(spacing: 0) {
            // Collapse handle
            Button {
                withAnimation(.spring(response: 0.35)) {
                    isExpanded = false
                }
            } label: {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
            }
            
            // Timer Display
            ZStack {
                // Background Ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timerColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                // Time Text
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 40, weight: .bold))
                        .monospacedDigit()
                    
                    Text("REST")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(1.5)
                }
            }
            .padding(.bottom, 20)
            
            // Duration Presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presetDurations, id: \.self) { duration in
                        DurationChip(
                            duration: duration,
                            isSelected: selectedDuration == duration,
                            action: {
                                selectDuration(duration)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
            
            // Control Buttons
            HStack(spacing: 12) {
                // Add Time Button
                Button {
                    addTime(15)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("15s")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 64, height: 40)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Play/Pause Button
                Button {
                    toggleTimer()
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Skip Button
                Button {
                    skip()
                } label: {
                    HStack(spacing: 4) {
                        Text("Skip")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "forward.fill")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 64, height: 40)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -10)
        )
    }
    
    // MARK: - Computed Properties
    
    private var progress: CGFloat {
        guard selectedDuration > 0 else { return 0 }
        return CGFloat(remainingTime / selectedDuration)
    }
    
    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "0:%02d", seconds)
    }
    
    private var timerColor: Color {
        if remainingTime <= 5 {
            return .orange
        }
        return .green
    }
    
    // MARK: - Actions
    
    private func startTimer() {
        stopTimer()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 0.1
            } else {
                timerComplete()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func toggleTimer() {
        if isRunning {
            stopTimer()
            isRunning = false
        } else {
            startTimer()
        }
    }
    
    private func selectDuration(_ duration: TimeInterval) {
        selectedDuration = duration
        remainingTime = duration
        if !isRunning {
            startTimer()
        }
    }
    
    private func addTime(_ seconds: TimeInterval) {
        remainingTime += seconds
        if remainingTime > selectedDuration {
            selectedDuration = remainingTime
        }
    }
    
    private func skip() {
        stopTimer()
        withAnimation(.spring(response: 0.35)) {
            isActive = false
        }
    }
    
    private func timerComplete() {
        stopTimer()
        
        let settings = UserSettingsManager.shared
        
        // Haptic feedback
        if settings.hapticFeedbackEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        // Play sound
        if settings.soundEnabled {
            AudioServicesPlaySystemSound(1007)
        }
        
        // Auto-dismiss after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.35)) {
                isActive = false
            }
        }
    }
}

// MARK: - Duration Chip (Compact)
struct DurationChip: View {
    let duration: TimeInterval
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(formattedDuration)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.green : Color(.tertiarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
    
    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 && seconds == 0 {
            return "\(minutes)m"
        } else if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "\(seconds)s"
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            FloatingRestTimer(
                isActive: .constant(true),
                selectedDuration: .constant(90)
            )
            .padding()
        }
    }
}
