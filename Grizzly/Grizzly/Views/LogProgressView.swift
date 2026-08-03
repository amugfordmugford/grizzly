import SwiftUI

struct LogProgressView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(WritingDataStore.self) private var dataStore

    @State private var selectedProjectId: Int?
    @State private var measure: Measure = .word
    @State private var countText = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var setTotal = false
    @State private var isSubmitting = false
    @State private var resultMessage: String?
    @State private var resultSucceeded = false

    private var selectedProject: Project? {
        dataStore.projects.first { $0.id == selectedProjectId }
    }

    var body: some View {
        Form {
            Section("Project") {
                if dataStore.projects.isEmpty {
                    Text("No projects found. Pull to refresh, or create one in TrackBear.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Project", selection: $selectedProjectId) {
                        if selectedProjectId == nil {
                            Text("Select a project").tag(Optional<Int>.none)
                        }
                        ForEach(dataStore.projects) { project in
                            Text(project.title).tag(Optional(project.id))
                        }
                    }
                }
            }

            Section("Progress") {
                Picker("Measure", selection: $measure) {
                    ForEach(Measure.allCases) { measure in
                        Text(measure.displayName).tag(measure)
                    }
                }
                HStack {
                    TextField(setTotal ? "New total \(measure.unitHint)" : "\(measure.unitHint.capitalized) added", text: $countText)
                        .keyboardType(.numberPad)
                    Text(measure.unitHint)
                        .foregroundStyle(.secondary)
                }
                Toggle("This is my new total, not an addition", isOn: $setTotal)
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }

            Section("Note") {
                TextField("Optional note", text: $note, axis: .vertical)
                    .lineLimit(1...4)
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Log Progress")
                    }
                }
                .disabled(!canSubmit || isSubmitting)

                if let resultMessage {
                    Label(resultMessage, systemImage: resultSucceeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(resultSucceeded ? .green : .red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Log Progress")
        .task {
            if dataStore.projects.isEmpty {
                await dataStore.refreshProjects(using: settings)
            }
            if selectedProjectId == nil {
                selectedProjectId = dataStore.projects.first?.id
            }
        }
        .refreshable {
            await dataStore.refreshProjects(using: settings)
        }
    }

    private var canSubmit: Bool {
        selectedProjectId != nil && Int(countText) != nil
    }

    private func submit() async {
        guard let workId = selectedProjectId, let count = Int(countText) else { return }
        isSubmitting = true
        resultMessage = nil
        defer { isSubmitting = false }

        let request = TallyCreateRequest(
            date: DateFormatter.trackBearDate.string(from: date),
            measure: measure,
            count: count,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note,
            workId: workId,
            setTotal: setTotal
        )

        switch await dataStore.logProgress(request, using: settings) {
        case .success:
            resultSucceeded = true
            resultMessage = "Logged!"
            countText = ""
            note = ""
        case .failure(let error):
            resultSucceeded = false
            resultMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        LogProgressView()
            .environment(AppSettingsStore())
            .environment(WritingDataStore())
    }
}
