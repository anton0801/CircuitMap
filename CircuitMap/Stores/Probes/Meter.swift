import Foundation

protocol Meter {
    func measure(deviceID: String) async throws -> [String: Any]
}

final class MultiMeter: Meter {

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func measure(deviceID: String) async throws -> [String: Any] {
        guard let url = forge(deviceID) else {
            throw Fault.miswired(at: "meter.url")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        let healthy = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
        guard healthy else {
            throw Fault.openLine(stage: "meter.http")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Fault.noiseFloor(at: "meter.json")
        }

        return json
    }

    private func forge(_ deviceID: String) -> URL? {
        var comps = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(Rail.appCode)")
        comps?.queryItems = [
            URLQueryItem(name: "devkey", value: Rail.meterKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        return comps?.url
    }
}
