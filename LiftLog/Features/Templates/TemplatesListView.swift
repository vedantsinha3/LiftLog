import SwiftUI
import SwiftData

struct TemplatesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse)
    private var templates: [WorkoutTemplate]
    
    @State private var showingCreateTemplate = false
    @State private var templateToEdit: WorkoutTemplate?
    @State private var templateToDelete: WorkoutTemplate?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    emptyState
                } else {
                    templatesList
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.secondarySystemBackground)))
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateView()
            }
            .sheet(item: $templateToEdit) { template in
                CreateTemplateView(templateToEdit: template)
            }
            .alert("Delete Template?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let template = templateToDelete {
                        deleteTemplate(template)
                    }
                }
            } message: {
                Text("This will permanently delete \"\(templateToDelete?.name ?? "this template")\".")
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No Templates Yet")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Create workout templates to quickly\nstart your favorite routines")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingCreateTemplate = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.headline)
                    Text("Create Template")
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
    }
    
    // MARK: - Templates List
    private var templatesList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(templates) { template in
                    TemplateCard(
                        template: template,
                        onEdit: { templateToEdit = template },
                        onDelete: {
                            templateToDelete = template
                            showDeleteAlert = true
                        }
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Actions
    private func deleteTemplate(_ template: WorkoutTemplate) {
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(template)
        }
        templateToDelete = nil
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: WorkoutTemplate
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(template.muscleGroupsSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit Template", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Template", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(.tertiarySystemBackground)))
                }
            }
            .padding(16)
            
            // Stats Bar
            HStack(spacing: 12) {
                TemplateStatBadge(icon: "figure.strengthtraining.traditional", value: "\(template.exerciseCount) exercises")
                TemplateStatBadge(icon: "number", value: "\(template.totalSets) sets")
                
                Spacer()
                
                // Expand Button
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Less" : "Details")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .foregroundStyle(.primary.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            
            // Expandable Exercise List
            if isExpanded && !template.sortedExercises.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 8) {
                        ForEach(template.sortedExercises) { templateExercise in
                            if let exercise = templateExercise.exercise {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color(.tertiarySystemBackground))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: exercise.primaryMuscle.icon)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.primary)
                                        )
                                    
                                    Text(exercise.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(templateExercise.defaultSetCount) sets")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color(.quaternarySystemFill)))
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Last Used Footer
            if let lastUsed = template.lastUsedAt {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                    Text("Last used \(lastUsed, style: .relative) ago")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Template Stat Badge
struct TemplateStatBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

#Preview {
    TemplatesListView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
