//
//  Theme.swift
//  CircuitMap
//
//  Central design system: colors (exact spec palette), fonts, spacing,
//  radii and cached formatters. iOS 14 safe.
//

import SwiftUI
import UIKit

// MARK: - Hex color helpers

extension UIColor {
    convenience init(hex: UInt, alpha: Double = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: CGFloat(alpha))
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self = Color(UIColor(hex: hex, alpha: alpha))
    }
    /// Adapts to the active interface style (light / dark).
    static func dynamic(light: UInt, dark: UInt) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Theme namespace (dark electric-yellow circuit schematic)

enum Theme {
    // Backgrounds (neutrals adapt to light/dark; the electric accents below stay fixed)
    static let bg        = Color.dynamic(light: 0xF5F1E6, dark: 0x16140C) // base
    static let bgDeep    = Color.dynamic(light: 0xEDE7D6, dark: 0x100E08) // depth
    static let bgSoft    = Color.dynamic(light: 0xFBF7EC, dark: 0x201C12) // soft
    static let card      = Color.dynamic(light: 0xFFFFFF, dark: 0x262113) // cards
    static let cardHover = Color.dynamic(light: 0xF3EEE0, dark: 0x322B19) // hover
    static let border    = Color.dynamic(light: 0xE3D9C0, dark: 0x463C20) // border

    // Primary (electric yellow)
    static let primary   = Color(hex: 0xFACC15)
    static let primaryActive = Color(hex: 0xEAB308)
    static let primaryHi  = Color(hex: 0xFDE047)

    // Secondary (copper) + circuit (cyan)
    static let copper    = Color(hex: 0xD97706)
    static let copperHi  = Color(hex: 0xFBBF24)
    static let circuit   = Color(hex: 0x38BDF8)

    // Status
    static let ok        = Color(hex: 0x22C55E)
    static let working   = Color(hex: 0x38BDF8)
    static let tight     = Color(hex: 0xFACC15)
    static let overload  = Color(hex: 0xEF4444)

    // Button colors
    static let dangerText = Color(hex: 0xFFFFFF)
    static let primaryText = Color(hex: 0x16140C)
    static let secondaryFill = Color(hex: 0x262113)
    static let secondaryText = Color(hex: 0xFEF3C7)

    // Text (adapts to light/dark)
    static let text       = Color.dynamic(light: 0x2A2410, dark: 0xFEF9E7) // primary
    static let mono       = Color.dynamic(light: 0x16140C, dark: 0xFFFFFF) // mono numerals
    static let textSecond = Color.dynamic(light: 0x7A6F4E, dark: 0xCDBF96) // secondary
    static let textMuted  = Color.dynamic(light: 0xAA9F7C, dark: 0x837A5C) // inactive

    // Glows
    static let sparkGlow   = Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.40)
    static let circuitGlow = Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.30)
    static let shadow      = Color.black.opacity(0.7)

    // Gradients
    static var background: LinearGradient {
        LinearGradient(colors: [bgDeep, bg, bgSoft],
                       startPoint: .top, endPoint: .bottom)
    }
    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [primaryHi, primary, primaryActive],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var copperGradient: LinearGradient {
        LinearGradient(colors: [copperHi, copper],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Spacing
    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let xl: CGFloat = 32
    }

    // Corner radii
    enum Radius {
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let pill: CGFloat = 100
    }

    // Typography
    static func title(_ size: CGFloat = 26) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func heading(_ size: CGFloat = 18) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    /// Monospaced numerals for watts / amps.
    static func numeric(_ size: CGFloat = 15, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Status helper colors

enum LoadStatus: String {
    case ok = "OK"
    case tight = "Low margin"
    case overload = "OVERLOAD"

    var color: Color {
        switch self {
        case .ok: return Theme.ok
        case .tight: return Theme.tight
        case .overload: return Theme.overload
        }
    }
    var icon: String {
        switch self {
        case .ok: return "checkmark.circle.fill"
        case .tight: return "exclamationmark.triangle.fill"
        case .overload: return "bolt.trianglebadge.exclamationmark.fill"
        }
    }
}

// MARK: - Cached formatters (iOS 14 safe — no .formatted())

enum Fmt {
    private static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f
    }()

    private static let date: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    private static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        return f
    }()

    /// Integer with thousands grouping (watts).
    static func watts(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: value)) ?? "0") + " W"
    }

    static func amps(_ value: Double) -> String {
        String(format: "%.1f A", value)
    }

    static func num(_ value: Double, _ digits: Int = 1) -> String {
        String(format: "%.\(digits)f", value)
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }

    /// Length formatted in the unit chosen in Settings ("m" or "ft").
    static func length(_ meters: Double) -> String {
        let unit = UserDefaults.standard.string(forKey: "lengthUnit") ?? "m"
        if unit == "ft" { return String(format: "%.0f ft", meters * 3.28084) }
        return String(format: "%.0f m", meters)
    }

    static func dateStr(_ d: Date) -> String { date.string(from: d) }
    static func dateTimeStr(_ d: Date) -> String { dateTime.string(from: d) }

    static func money(_ value: Double, symbol: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return symbol + (f.string(from: NSNumber(value: value)) ?? "0")
    }
}

// MARK: - Keyboard dismissal

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
