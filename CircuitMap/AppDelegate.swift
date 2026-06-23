import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var launch: LaunchTemplate = CircuitLaunch(host: self)
    private let node = Node()
    private let tapper = Tapper()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        launch.boot()

        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            tapper.clamp(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    @objc private func onActivation() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: RailKey.fcm)
            UserDefaults.standard.set(t, forKey: RailKey.push)
            UserDefaults(suiteName: Rail.suiteGrid)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        tapper.clamp(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        tapper.clamp(response.notification.request.content.userInfo)
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        tapper.clamp(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        node.takeSignal(data)
    }

    func onConversionDataFail(_ error: Error) {
        node.takeSignal([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }

    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        node.takeJumpers(link.clickEvent)
    }
}

class LaunchTemplate {

    final func boot() {
        forge()
        couple()
        arm()
    }

    func forge() {}
    func couple() {}
    func arm() {}
}

final class CircuitLaunch: LaunchTemplate {

    private weak var host: AppDelegate?

    init(host: AppDelegate) {
        self.host = host
    }

    override func forge() {
        FirebaseApp.configure()

        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = Rail.meterKey
        sdk.appleAppID = Rail.appCode
        sdk.delegate = host
        sdk.deepLinkDelegate = host
        sdk.isDebug = false
    }

    override func couple() {
        Messaging.messaging().delegate = host
        UIApplication.shared.registerForRemoteNotifications()
    }

    override func arm() {
        UNUserNotificationCenter.current().delegate = host
    }
}

final class Node: NSObject {

    private var signalBuffer: [AnyHashable: Any] = [:]
    private var jumperBuffer: [AnyHashable: Any] = [:]

    func takeSignal(_ data: [AnyHashable: Any]) {
        signalBuffer = data
        armFuse()
        if !jumperBuffer.isEmpty { bridge() }
    }

    func takeJumpers(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: RailKey.primed) else { return }
        jumperBuffer = data
        NotificationCenter.default.post(
            name: .jumpersArrived,
            object: nil,
            userInfo: ["deeplinksData": data]
        )
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fire), object: nil)
        if !signalBuffer.isEmpty { bridge() }
    }

    private func armFuse() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fire), object: nil)
        perform(#selector(fire), with: nil, afterDelay: 2.5)
    }

    @objc private func fire() {
        bridge()
    }

    private func bridge() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fire), object: nil)

        var merged = signalBuffer
        for (k, v) in jumperBuffer {
            let tag = "deep_\(k)"
            if merged[tag] == nil { merged[tag] = v }
        }

        NotificationCenter.default.post(
            name: .signalArrived,
            object: nil,
            userInfo: ["conversionData": merged]
        )
    }
}

final class Tapper {

    private enum Lead {
        case direct
        case nested
        case aps
        case custom

        func extract(_ p: [AnyHashable: Any]) -> String? {
            switch self {
            case .direct:
                return p["url"] as? String
            case .nested:
                return (p["data"] as? [AnyHashable: Any])?["url"] as? String
            case .aps:
                return ((p["aps"] as? [AnyHashable: Any])?["data"] as? [AnyHashable: Any])?["url"] as? String
            case .custom:
                return (p["custom"] as? [AnyHashable: Any])?["url"] as? String
            }
        }
    }

    func clamp(_ payload: [AnyHashable: Any]) {
        let leads: [Lead] = [.direct, .nested, .aps, .custom]
        guard let url = leads.lazy.compactMap({ $0.extract(payload) }).first else { return }

        UserDefaults.standard.set(url, forKey: RailKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NotificationCenter.default.post(
                name: .screenWake,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
}
