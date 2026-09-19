import SwiftUI

struct ProjectsView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(WritingDataStore.self) private var dataStore

    var body: some View {
        List {
            if dataStore.projects.isEmpty && !dataStore.isLoadingProjects {
                ContentUnavailableView(
                    "No Projects Yet",
                    systemImage: "books.vertical",
                    description: Text("Create a project in TrackBear to see it here.")
                )
            }
            ForEach(Array(dataStore.projects.enumerated()), id: \.element.id) { index, project in
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    EdgeAccentCard(accentColor: AccentPalette.color(at: index)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(project.title)
                                    .font(.headline)
                                if project.starred == true {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                }
                            }
                            if let phase = project.phase, !phase.isEmpty {
                                Text(phase)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let totals = project.totals {
                                totalsBadges(totals)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle("Projects")
        .refreshable {
            await dataStore.refreshProjects(using: settings)
        }
        .task {
            if dataStore.projects.isEmpty {
                await dataStore.refreshProjects(using: settings)
            }
        }
        .overlay {
            if dataStore.isLoadingProjects && dataStore.projects.isEmpty {
                ProgressView()
            }
        }
        .alert("Couldn't Load Projects", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dataStore.lastError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { dataStore.lastError != nil },
            set: { if !$0 { dataStore.lastError = nil } }
        )
    }

    @ViewBuilder
    private func totalsBadges(_ totals: MeasureCounts) -> some View {
        let parts: [(Measure, Int)] = Measure.allCases.compactMap { measure in
            let value = totals.value(for: measure)
            return value > 0 ? (measure, value) : nil
        }
        if parts.isEmpty {
            Text("No progress logged yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 6) {
                ForEach(parts, id: \.0) { measure, value in
                    Text("\(value) \(measure.unitHint)")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectsView()
            .environment(AppSettingsStore())
            .environment(WritingDataStore())
    }
}
