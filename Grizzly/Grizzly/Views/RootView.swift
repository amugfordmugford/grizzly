import SwiftUI

struct RootView: View {
    @Environment(AppSettingsStore.self) private var settings
    @State private var dataStore = WritingDataStore()

    var body: some View {
        if settings.isConfigured {
            TabView {
                Tab("Log", systemImage: "pencil.and.scribble") {
                    NavigationStack {
                        LogProgressView()
                    }
                }
                Tab("Projects", systemImage: "books.vertical") {
                    NavigationStack {
                        ProjectsView()
                    }
                }
                Tab("History", systemImage: "clock.arrow.circlepath") {
                    NavigationStack {
                        HistoryView()
                    }
                }
                Tab("Settings", systemImage: "gearshape") {
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
            .environment(dataStore)
        } else {
            NavigationStack {
                SettingsView(isOnboarding: true)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppSettingsStore())
}
