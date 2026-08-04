import SwiftUI

struct ProjectDetailView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(WritingDataStore.self) private var dataStore

    let project: Project

    @State private var tallies: [Tally] = []
    @State private var isLoading = false
    @State private var lastError: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.title)
                            .font(.title2.bold())
                        if project.starred == true {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    if let phase = project.phase, !phase.isEmpty {
                        Text(phase)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Totals") {
                if totalsRows.isEmpty {
                    Text("No progress logged yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(totalsRows, id: \.0) { measure, value in
                        LabeledContent(measure.displayName, value: "\(value) \(measure.unitHint)")
                    }
                }
            }

            Section("History") {
                if tallies.isEmpty && !isLoading {
                    Text("No entries logged for this project yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(tallies) { tally in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(tally.count) \(tally.measure.unitHint)")
                                .font(.headline)
                            Spacer()
                            Text(tally.date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let note = tally.note, !note.isEmpty {
                            Text(note)
                                .font(.footnote)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await load()
        }
        .task {
            await load()
        }
        .overlay {
            if isLoading && tallies.isEmpty {
                ProgressView()
            }
        }
        .alert("Something Went Wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(lastError ?? "")
        }
    }

    private var totalsRows: [(Measure, Int)] {
        guard let totals = project.totals else { return [] }
        return Measure.allCases.compactMap { measure in
            let value = totals.value(for: measure)
            return value > 0 ? (measure, value) : nil
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { lastError != nil },
            set: { if !$0 { lastError = nil } }
        )
    }

    private func load() async {
        guard let client = settings.makeClient() else {
            lastError = TrackBearError.notConfigured.errorDescription
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            tallies = try await client.listTallies(workId: project.id)
                .sorted { $0.date > $1.date }
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        guard let client = settings.makeClient() else { return }
        let toDelete = offsets.map { tallies[$0] }
        tallies.remove(atOffsets: offsets)
        Task {
            for tally in toDelete {
                do {
                    try await client.deleteTally(id: tally.id)
                } catch {
                    lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
            await dataStore.refreshProjects(using: settings)
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(
            id: 1, uuid: nil, createdAt: nil, updatedAt: nil, state: nil, ownerId: nil,
            title: "My Novel", description: nil, phase: "Drafting",
            startingBalance: nil, cover: nil, starred: true, displayOnProfile: nil,
            totals: MeasureCounts(word: 12000, time: nil, page: nil, chapter: nil, scene: nil, line: nil),
            lastUpdated: nil
        ))
        .environment(AppSettingsStore())
        .environment(WritingDataStore())
    }
}
