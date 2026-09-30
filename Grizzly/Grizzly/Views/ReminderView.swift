import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ReminderView: View {
    @Environment(ReminderStore.self) private var reminderStore

    var body: some View {
        @Bindable var reminderStore = reminderStore

        Form {
            Section {
                Toggle("Daily writing reminder", isOn: $reminderStore.isEnabled)
                if reminderStore.isEnabled {
                    DatePicker("Remind me at", selection: $reminderStore.time, displayedComponents: .hourAndMinute)
                }
            } footer: {
                Text(reminderStore.isEnabled
                     ? "Every day at this time, you'll get a notification: \"This is a gentle reminder to write today!\""
                     : "Turn this on to get a daily nudge to log some writing.")
            }

            if reminderStore.permissionDenied {
                Section {
                    Label("Notifications are turned off for Grizzly, so this reminder won't appear.", systemImage: "bell.slash.fill")
                        .foregroundStyle(.red)
                        .font(.footnote)
                    Button("Open Settings") {
                        openSystemSettings()
                    }
                }
            }
        }
        .warmBackground()
        .navigationTitle("Reminders")
        .task {
            reminderStore.refreshIfEnabled()
        }
    }

    private func openSystemSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }
}

#Preview {
    NavigationStack {
        ReminderView()
            .environment(ReminderStore())
    }
}
