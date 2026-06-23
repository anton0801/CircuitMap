import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol Relay {
    func send(payload: [String: Any]) async throws -> String
}

final class BusRelay: Relay {

    private let session: URLSession
    private let baseGap: Double = 93.0
    private let ceiling: Int = 3

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    private var agent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""

    func send(payload: [String: Any]) async throws -> String {
        let request = try couple(payload)
        let backoffs = sequence(first: baseGap) { $0 * 2 }

        var attempt = 0
        var last: Error? = nil

        for gap in backoffs {
            if attempt >= ceiling { break }

            do {
                return try await probe(request)
            } catch let fault as Fault where fault.isSealed {
                throw fault
            } catch let fault as Fault {
                if case .saturated(let cooldown) = fault {
                    try await idle(cooldown)
                    attempt += 1
                    continue
                }
                last = fault
                attempt += 1
                if attempt < ceiling { try await idle(gap) }
            } catch {
                last = error
                attempt += 1
                if attempt < ceiling { try await idle(gap) }
            }
        }

        throw last ?? Fault.openLine(stage: "relay.exhausted")
    }

    private func couple(_ payload: [String: Any]) throws -> URLRequest {
        guard let endpoint = URL(string: Rail.relayEndpoint) else {
            throw Fault.miswired(at: "relay.url")
        }

        var body: [String: Any] = payload
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(Rail.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: RailKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func probe(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw Fault.openLine(stage: "relay.response")
        }

        if http.statusCode == 404 {
            throw Fault.fuseBlown(httpCode: 404)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Fault.noiseFloor(at: "relay.json")
        }

        guard let ok = json["ok"] as? Bool else {
            throw Fault.noiseFloor(at: "relay.missingOk")
        }

        guard ok else {
            throw Fault.gridDown(reason: "okFalse")
        }

        guard let url = json["url"] as? String, !url.isEmpty else {
            throw Fault.noiseFloor(at: "relay.missingURL")
        }

        return url
    }

    private func idle(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
