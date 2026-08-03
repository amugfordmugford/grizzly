import SwiftUI

struct ProjectsView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(WritingDataStore.self) private var dataStore

    var body: some View {
        List {
            if dataStore.projects.isEmpty && !dataStore.isLoadingProjects {
                ContentUnavailableView(
                    "No Projects Yet",
                    systemImage: "book.closed",
                    description: Text("Create a project in TrackBear to see it here.")
                )
            }
            ForEach(dataStore.projects) { project in
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
                        Text(totalsSummary(totals))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
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

    private func totalsSummary(_ totals: MeasureCounts) -> String {
        let parts: [(Measure, Int)] = Measure.allCases.compactMap { measure in
            let value = totals.value(for: measure)
            return value > 0 ? (measure, value) : nil
        }
        guard !parts.isEmpty else { return "No progress logged yet" }
        return parts.map { "\($0.1) \($0.0.unitHint)" }.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        ProjectsView()
            .environment(AppSettingsStore())
            .environment(WritingDataStore())
    }
}
