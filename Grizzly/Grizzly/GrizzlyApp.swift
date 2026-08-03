import SwiftUI

@main
struct GrizzlyApp: App {
    @State private var settings = AppSettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
    }
}
