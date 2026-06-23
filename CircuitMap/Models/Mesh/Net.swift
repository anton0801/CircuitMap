import Foundation

struct NetLog: Codable {
    let signal: [String: String]
    let jumpers: [String: String]
    let loadURL: String?
    let loadMode: String?
    let floating: Bool
    let breakerArmed: Bool
    let breakerTripped: Bool
    let breakerSetAt: Date?
}

struct Net {
    var signal: [String: String] = [:]
    var jumpers: [String: String] = [:]
    var loadURL: String? = nil
    var loadMode: String? = nil
    var floating: Bool = true
    var soldered: Bool = false
    var recharged: Bool = false
    var breakerArmed: Bool = false
    var breakerTripped: Bool = false
    var breakerSetAt: Date? = nil

    var signalPresent: Bool { !signal.isEmpty }
    var organicFloat: Bool { signal["af_status"] == "Organic" }

    var breakerDue: Bool {
        guard !breakerArmed && !breakerTripped else { return false }
        if let date = breakerSetAt {
            return Date().timeIntervalSince(date) / 86400 >= 3
        }
        return true
    }

    static func rebuild(from log: NetLog) -> Net {
        var n = Net()
        n.signal = log.signal
        n.jumpers = log.jumpers
        n.loadURL = log.loadURL
        n.loadMode = log.loadMode
        n.floating = log.floating
        n.breakerArmed = log.breakerArmed
        n.breakerTripped = log.breakerTripped
        n.breakerSetAt = log.breakerSetAt
        return n
    }

    func log() -> NetLog {
        NetLog(
            signal: signal,
            jumpers: jumpers,
            loadURL: loadURL,
            loadMode: loadMode,
            floating: floating,
            breakerArmed: breakerArmed,
            breakerTripped: breakerTripped,
            breakerSetAt: breakerSetAt
        )
    }
}

enum Charge: Equatable {
    case tracing
    case askSwitch
    case energized
    case blown
}

enum Hop {
    case tap
    case idle
    case recharge
    case energize
}
