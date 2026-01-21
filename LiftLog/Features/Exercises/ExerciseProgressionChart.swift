import SwiftUI
import Charts

struct ExerciseProgressionChart: View {
    let exercise: Exercise
    let progressionData: [ExerciseProgressionPoint]
    
    private let settings = UserSettingsManager.shared
    
    private var hasData: Bool {
        !progressionData.isEmpty
    }
    
    private var personalBest: Double? {
        progressionData.map { $0.maxWeight }.max()
    }
    
    private var totalWorkouts: Int {
        progressionData.count
    }
    
    private var convertedData: [(date: Date, weight: Double)] {
        progressionData.map { point in
            (date: point.date, weight: point.maxWeight * settings.weightUnit.fromLbsFactor)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Progression")
                .font(.title3)
                .fontWeight(.bold)
            
            if hasData {
                // Stats Row
                statsRow
                
                // Chart
                chartView
            } else {
                emptyState
            }
        }
    }
    
    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBox(
                title: "Personal Best",
                value: personalBest != nil ? settings.formatWeightWithUnit(personalBest!) : "-",
                icon: "trophy.fill",
                color: .orange
            )
            
            StatBox(
                title: "Workouts",
                value: "\(totalWorkouts)",
                icon: "flame.fill",
                color: .red
            )
        }
    }
    
    // MARK: - Chart View
    private var chartView: some View {
        Chart {
            ForEach(convertedData, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Color.black)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.black.opacity(0.15), Color.black.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Color.black)
                .symbolSize(40)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text("\(Int(weight))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 200)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            
            Text("No history yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
//            Text("Complete a workout to track progress")
//                .font(.caption)
//                .foregroundStyle(.tertiary)
//                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Stat Box
private struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    ExerciseProgressionChart(
        exercise: ExerciseDataLoader.sampleExercise(),
        progressionData: [
            ExerciseProgressionPoint(date: Date().addingTimeInterval(-86400 * 30), maxWeight: 135, totalSets: 3, totalReps: 24),
            ExerciseProgressionPoint(date: Date().addingTimeInterval(-86400 * 23), maxWeight: 145, totalSets: 3, totalReps: 21),
            ExerciseProgressionPoint(date: Date().addingTimeInterval(-86400 * 16), maxWeight: 155, totalSets: 4, totalReps: 28),
            ExerciseProgressionPoint(date: Date().addingTimeInterval(-86400 * 9), maxWeight: 165, totalSets: 3, totalReps: 18),
            ExerciseProgressionPoint(date: Date().addingTimeInterval(-86400 * 2), maxWeight: 175, totalSets: 4, totalReps: 24)
        ]
    )
    .padding()
}
