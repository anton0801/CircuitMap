//
//  NotificationManager.swift
//  CircuitMap
//
//  Thin wrapper over UNUserNotificationCenter for local reminders.
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var authorized: Bool = false

    private init() { refreshStatus() }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
            }
        }
    }

    func requestAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    self.authorized = granted
                    completion?(granted)
                }
            }
    }

    /// Schedules a one-off reminder. Uses the reminder id as the request id
    /// so it can be cancelled later.
    func schedule(_ reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.kind.rawValue
        content.body = reminder.title
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString,
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancel(_ reminder: Reminder) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Re-syncs all enabled reminders (used after edits / app launch).
    func sync(_ reminders: [Reminder]) {
        cancelAll()
        for r in reminders where r.enabled && r.date > Date() {
            schedule(r)
        }
    }
}
