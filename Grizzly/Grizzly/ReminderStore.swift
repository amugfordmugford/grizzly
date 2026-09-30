import Foundation
import Observation
import UserNotifications

/// Manages the daily "remember to write" local notification: whether it's on,
/// what time it fires, and the OS notification-permission state behind it.
@Observable
final class ReminderStore: NSObject {
    private static let enabledKey = "write-reminder-enabled"
    private static let hourKey = "write-reminder-hour"
    private static let minuteKey = "write-reminder-minute"
    private static let notificationIdentifier = "write-reminder"
    private static let defaultHour = 20

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled {
                requestAuthorizationAndSchedule()
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
            }
        }
    }

    /// Only the hour/minute components are meaningful; the date itself is ignored.
    var time: Date {
        didSet {
            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            UserDefaults.standard.set(components.hour, forKey: Self.hourKey)
            UserDefaults.standard.set(components.minute, forKey: Self.minuteKey)
            if isEnabled { schedule() }
        }
    }

    var permissionDenied = false

    override init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        var components = DateComponents()
        components.hour = UserDefaults.standard.object(forKey: Self.hourKey) as? Int ?? Self.defaultHour
        components.minute = UserDefaults.standard.object(forKey: Self.minuteKey) as? Int ?? 0
        self.time = Calendar.current.date(from: components) ?? Date()
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Re-confirms authorization and re-arms the notification. Safe to call
    /// whenever the Reminders screen appears - a no-op if already authorized
    /// and scheduled, since `schedule()` replaces any pending request.
    func refreshIfEnabled() {
        guard isEnabled else { return }
        requestAuthorizationAndSchedule()
    }

    private func requestAuthorizationAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.permissionDenied = !granted
                if granted {
                    self.schedule()
                } else {
                    self.isEnabled = false
                }
            }
        }
    }

    private func schedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Grizzly"
        content.body = "This is a gentle reminder to write today!"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.notificationIdentifier, content: content, trigger: trigger)
        center.add(request)
    }
}

extension ReminderStore: UNUserNotificationCenterDelegate {
    /// Lets the reminder still show a banner if the app happens to be open
    /// in the foreground when it fires.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
