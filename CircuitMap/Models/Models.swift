//
//  Models.swift
//  CircuitMap
//
//  All Codable value types + enums. The single AppData root is persisted
//  as JSON. iOS 14 safe.
//

import Foundation

// MARK: - Enums

enum SupplyPhase: String, Codable, CaseIterable, Identifiable {
    case single = "1-phase"
    case three = "3-phase"
    var id: String { rawValue }
    var legCount: Int { self == .single ? 1 : 3 }
    var icon: String { self == .single ? "bolt.fill" : "bolt.horizontal.fill" }
}

enum CircuitKind: String, Codable, CaseIterable, Identifiable {
    case lighting = "Lighting"
    case socket = "Socket"
    case power = "Power"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .lighting: return "lightbulb.fill"
        case .socket: return "poweroutlet.type.b.fill"
        case .power: return "bolt.batteryblock.fill"
        }
    }
    /// Default breaker rating (A) suggested for the kind.
    var defaultRating: Int {
        switch self {
        case .lighting: return 10
        case .socket: return 16
        case .power: return 25
        }
    }
    /// Voltage-drop limit (%) used by the advisor (lighting is stricter).
    var dropLimit: Double { self == .lighting ? 3.0 : 5.0 }
}

enum Fault: Error, CustomStringConvertible {
    case deadShort(at: String)
    case miswired(at: String)
    case openLine(stage: String)
    case saturated(cooldown: TimeInterval)
    case fuseBlown(httpCode: Int)
    case gridDown(reason: String)
    case noiseFloor(at: String)

    var description: String {
        switch self {
        case .deadShort(let at): return "deadShort(\(at))"
        case .miswired(let at): return "miswired(\(at))"
        case .openLine(let stage): return "openLine(\(stage))"
        case .saturated(let cd): return "saturated(cd=\(cd))"
        case .fuseBlown(let code): return "fuseBlown(\(code))"
        case .gridDown(let reason): return "gridDown(\(reason))"
        case .noiseFloor(let at): return "noiseFloor(\(at))"
        }
    }

    var isSealed: Bool {
        switch self {
        case .fuseBlown, .gridDown: return true
        default: return false
        }
    }
}

enum CableType: String, Codable, CaseIterable, Identifiable {
    case copperPVC = "Cu / PVC"
    case copperXLPE = "Cu / XLPE"
    case aluminium = "Aluminium"
    var id: String { rawValue }
    /// Resistivity Ω·mm²/m (reference, 20°C).
    var resistivity: Double {
        switch self {
        case .copperPVC, .copperXLPE: return 0.0175
        case .aluminium: return 0.0282
        }
    }
}

enum PhaseLeg: String, Codable, CaseIterable, Identifiable {
    case l1 = "L1"
    case l2 = "L2"
    case l3 = "L3"
    var id: String { rawValue }
}

enum PointKind: String, Codable, CaseIterable, Identifiable {
    case socket = "Socket"
    case light = "Light"
    case output = "Output"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .socket: return "poweroutlet.type.b"
        case .light: return "lightbulb"
        case .output: return "cable.connector"
        }
    }
    /// Typical mounting height in cm (ergonomic reference).
    var standardHeight: Int {
        switch self {
        case .socket: return 30
        case .light: return 230
        case .output: return 110
        }
    }
}

enum RegionStandard: String, Codable, CaseIterable, Identifiable {
    case iec = "IEC / EU"
    case uk = "UK (BS 7671)"
    case us = "US (NEC)"
    var id: String { rawValue }
    var defaultVoltage: Int {
        switch self {
        case .iec: return 230
        case .uk: return 230
        case .us: return 120
        }
    }
    var note: String {
        switch self {
        case .iec: return "230 V, 50 Hz — copper PVC common."
        case .uk: return "Ring & radial finals, RCBO protection."
        case .us: return "120/240 V split-phase, AWG sizing."
        }
    }
}

enum HistoryKind: String, Codable {
    case added = "Added"
    case balanced = "Balanced"
    case checked = "Checked"
    case edited = "Edited"
    case removed = "Removed"

    var icon: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .balanced: return "arrow.left.arrow.right.circle.fill"
        case .checked: return "checkmark.seal.fill"
        case .edited: return "pencil.circle.fill"
        case .removed: return "trash.circle.fill"
        }
    }
}

enum ReminderKind: String, Codable, CaseIterable, Identifiable {
    case checkBalance = "Check balance"
    case buyCable = "Buy cable"
    case inspect = "Inspect panel"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .checkBalance: return "scalemass.fill"
        case .buyCable: return "cart.fill"
        case .inspect: return "magnifyingglass.circle.fill"
        }
    }
}

// MARK: - Entities
enum RailKey {
    static let loadURL = "cm_load_url"
    static let loadMode = "cm_load_mode"
    static let primed = "cm_primed"

    static let breakerArmed = "cm_breaker_armed"
    static let breakerTripped = "cm_breaker_tripped"
    static let breakerSetAt = "cm_breaker_set_at"

    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

extension Notification.Name {
    static let signalArrived = Notification.Name("ConversionDataReceived")
    static let jumpersArrived = Notification.Name("deeplink_values")
    static let screenWake = Notification.Name("LoadTempURL")
}


struct Supply: Codable, Equatable {
    var phase: SupplyPhase = .single
    var voltage: Int = 230
    var mainBreaker: Int = 40 // A
    var standard: RegionStandard = .iec
}

struct Circuit: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var kind: CircuitKind
    var breakerRating: Int            // A
    var cableType: CableType = .copperPVC
    var cableArea: Double = 2.5       // mm²
    var cableLength: Double = 12      // m
    var leg: PhaseLeg = .l1
    var colorHex: UInt = 0xFACC15
}

struct Device: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var watts: Double
    var demandFactor: Double = 1.0    // 0...1 utilisation
    var roomID: UUID?
    var circuitID: UUID?
    var iconName: String = "powerplug.fill"

    /// Effective load contribution.
    var load: Double { watts * demandFactor }
}

struct Room: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var colorHex: UInt = 0x38BDF8
    var icon: String = "square.split.bottomrightquarter.fill"
}

struct SocketPoint: Codable, Identifiable, Equatable {
    var id = UUID()
    var roomID: UUID
    var kind: PointKind
    var count: Int = 1
    var height: Int                   // cm
    var circuitID: UUID?
    var done: Bool = false            // ergonomics checklist tick
}

struct SafetyNote: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var flagged: Bool = false         // requires attention
    var zone: String = "General"
    var resolved: Bool = false
}

struct PhotoMarker: Codable, Identifiable, Equatable {
    var id = UUID()
    var caption: String
    var imageRef: String              // filename in PhotoStore
    var date: Date = Date()
}

struct HistoryEvent: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: HistoryKind
    var detail: String
    var date: Date = Date()
}

struct Reminder: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var kind: ReminderKind
    var date: Date
    var enabled: Bool = true
}

/// Editable unit prices for the cost estimate (per-currency-neutral numbers).
struct PriceBook: Codable, Equatable {
    var breakerEach: Double = 4.5
    var socketEach: Double = 3.0
    var switchEach: Double = 3.5
    /// Cable price per metre keyed by cross-section (mm²).
    var cablePerMetre: [String: Double] = [
        "1.5": 0.8, "2.5": 1.2, "4": 1.9, "6": 2.8, "10": 4.5, "16": 7.0
    ]
}

// MARK: - Root

struct AppData: Codable, Equatable {
    var supply = Supply()
    var circuits: [Circuit] = []
    var devices: [Device] = []
    var rooms: [Room] = []
    var points: [SocketPoint] = []
    var notes: [SafetyNote] = []
    var photos: [PhotoMarker] = []
    var history: [HistoryEvent] = []
    var reminders: [Reminder] = []
    var prices = PriceBook()
}
