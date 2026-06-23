import Foundation

protocol Etch {
    func etch(_ log: NetLog)
    func tagLoad(url: String, mode: String)
    func raisePrimedFlag()
    func readback() -> NetLog
}

final class CopperEtch: Etch {

    private let fm = FileManager.default
    private let vaultDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.vaultDir = docs.appendingPathComponent(Rail.gridVault, isDirectory: true)
        if !fm.fileExists(atPath: vaultDir.path) {
            try? fm.createDirectory(at: vaultDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: Rail.suiteGrid) ?? .standard
    }

    private var netURL: URL {
        vaultDir.appendingPathComponent(Rail.netFile)
    }

    func etch(_ log: NetLog) {
        let ghost = GhostNet(
            signal: maskMap(log.signal),
            jumpers: maskMap(log.jumpers),
            loadURL: log.loadURL,
            loadMode: log.loadMode,
            floating: log.floating,
            breakerArmed: log.breakerArmed,
            breakerTripped: log.breakerTripped,
            breakerSetAt: log.breakerSetAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        do {
            let data = try encoder.encode(ghost)
            try data.write(to: netURL, options: .atomic)
        } catch {
            print("\(Rail.logPlug) Etch write failed: \(error)")
        }

        for store in [suiteStore, homeStore] {
            store.set(log.breakerArmed, forKey: RailKey.breakerArmed)
            store.set(log.breakerTripped, forKey: RailKey.breakerTripped)
            if let date = log.breakerSetAt {
                store.set(date.timeIntervalSince1970, forKey: RailKey.breakerSetAt)
            }
        }
    }

    func tagLoad(url: String, mode: String) {
        suiteStore.set(url, forKey: RailKey.loadURL)
        homeStore.set(url, forKey: RailKey.loadURL)
        suiteStore.set(mode, forKey: RailKey.loadMode)
    }

    func raisePrimedFlag() {
        suiteStore.set(true, forKey: RailKey.primed)
        homeStore.set(true, forKey: RailKey.primed)
    }

    func readback() -> NetLog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        if fm.fileExists(atPath: netURL.path),
           let data = try? Data(contentsOf: netURL),
           let ghost = try? decoder.decode(GhostNet.self, from: data) {
            return NetLog(
                signal: unmaskMap(ghost.signal),
                jumpers: unmaskMap(ghost.jumpers),
                loadURL: ghost.loadURL,
                loadMode: ghost.loadMode,
                floating: ghost.floating,
                breakerArmed: ghost.breakerArmed,
                breakerTripped: ghost.breakerTripped,
                breakerSetAt: ghost.breakerSetAt
            )
        }

        return readbackFromMirror()
    }

    private func readbackFromMirror() -> NetLog {
        let loadURL = homeStore.string(forKey: RailKey.loadURL)
            ?? suiteStore.string(forKey: RailKey.loadURL)
        let loadMode = suiteStore.string(forKey: RailKey.loadMode)
        let primed = suiteStore.bool(forKey: RailKey.primed)

        let armed = suiteStore.bool(forKey: RailKey.breakerArmed)
            || homeStore.bool(forKey: RailKey.breakerArmed)
        let tripped = suiteStore.bool(forKey: RailKey.breakerTripped)
            || homeStore.bool(forKey: RailKey.breakerTripped)
        let setTs = suiteStore.double(forKey: RailKey.breakerSetAt)
        let setAt: Date? = setTs > 0 ? Date(timeIntervalSince1970: setTs) : nil

        return NetLog(
            signal: [:],
            jumpers: [:],
            loadURL: loadURL,
            loadMode: loadMode,
            floating: !primed,
            breakerArmed: armed,
            breakerTripped: tripped,
            breakerSetAt: setAt
        )
    }

    private func maskMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = mask(pair.value) }
    }

    private func unmaskMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = unmask(pair.value) ?? pair.value }
    }

    private func mask(_ input: String) -> String {
        Data(input.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: ".")
            .replacingOccurrences(of: "/", with: "_")
    }

    private func unmask(_ input: String) -> String? {
        let restored = input
            .replacingOccurrences(of: ".", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: restored),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct GhostNet: Codable {
    let signal: [String: String]
    let jumpers: [String: String]
    let loadURL: String?
    let loadMode: String?
    let floating: Bool
    let breakerArmed: Bool
    let breakerTripped: Bool
    let breakerSetAt: Date?
}
