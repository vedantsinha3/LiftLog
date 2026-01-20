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
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
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
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.on.doc")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Templates Yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Create workout templates to quickly start your favorite routines")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingCreateTemplate = true
            } label: {
                Label("Create Template", systemImage: "plus")
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
    
    // MARK: - Templates List
    private var templatesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Actions
    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        templateToDelete = nil
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: WorkoutTemplate
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    
                    Text(template.muscleGroupsSummary)
                        .font(.subheadline)
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
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
            
            // Stats
            HStack(spacing: 16) {
                Label("\(template.exerciseCount) exercises", systemImage: "dumbbell.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(template.totalSets) sets", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Exercise Preview
            if !template.sortedExercises.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(template.sortedExercises.prefix(3)) { templateExercise in
                        if let exercise = templateExercise.exercise {
                            HStack(spacing: 8) {
                                Image(systemName: exercise.primaryMuscle.icon)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .frame(width: 16)
                                
                                Text(exercise.name)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(templateExercise.defaultSetCount) sets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if template.exerciseCount > 3 {
                        Text("+\(template.exerciseCount - 3) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Last Used
            if let lastUsed = template.lastUsedAt {
                HStack {
                    Spacer()
                    Text("Last used \(lastUsed, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TemplatesListView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
