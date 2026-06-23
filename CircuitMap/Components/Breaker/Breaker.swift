import Foundation
import UIKit
import UserNotifications

protocol Breaker {
    func arm() async -> Bool
    func wireGrid()
}

final class PanelBreaker: Breaker {

    func arm() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let toggle = OneToggle()
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                    print("\(Rail.logPlug) Breaker error: \(error)")
                }
                DispatchQueue.main.async {
                    guard toggle.flip() else { return }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func wireGrid() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class OneToggle {
    private var flipped = false
    private let lock = NSLock()

    func flip() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !flipped else { return false }
        flipped = true
        return true
    }
}
