import SwiftUI

@main
struct GrizzlyApp: App {
    @State private var settings = AppSettingsStore()
    @State private var reminderStore = ReminderStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(reminderStore)
        }
    }
}
