import SwiftUI
import AVFoundation

// MARK: - Rest Timer View
struct RestTimerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedDuration: TimeInterval
    
    @State private var remainingTime: TimeInterval
    @State private var isRunning = true
    @State private var timer: Timer?
    
    let presetDurations: [TimeInterval] = [30, 60, 90, 120, 180, 300]
    
    init(isPresented: Binding<Bool>, selectedDuration: Binding<TimeInterval>) {
        self._isPresented = isPresented
        self._selectedDuration = selectedDuration
        self._remainingTime = State(initialValue: selectedDuration.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)
            
            // Timer Display
            ZStack {
                // Background Ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 160, height: 160)
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timerColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                // Time Text
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Text("REST")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(1.5)
                }
            }
            .padding(.bottom, 24)
            
            // Duration Presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presetDurations, id: \.self) { duration in
                        DurationButton(
                            duration: duration,
                            isSelected: selectedDuration == duration,
                            action: {
                                selectDuration(duration)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
            
            // Control Buttons
            HStack(spacing: 16) {
                // Add Time Button
                Button {
                    addTime(15)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("15s")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 80, height: 48)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Play/Pause Button
                Button {
                    toggleTimer()
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Skip Button
                Button {
                    skip()
                } label: {
                    HStack(spacing: 6) {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Image(systemName: "forward.fill")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .frame(width: 80, height: 48)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -10)
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
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
        return .black
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
        isPresented = false
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
            AudioServicesPlaySystemSound(1007) // Standard iOS notification sound
        }
        
        // Auto-dismiss after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

// MARK: - Duration Button
struct DurationButton: View {
    let duration: TimeInterval
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(formattedDuration)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.black : Color(.tertiarySystemBackground))
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
            RestTimerView(
                isPresented: .constant(true),
                selectedDuration: .constant(90)
            )
        }
    }
}
