//
//  ElectricalReference.swift
//  CircuitMap
//
//  Reference tables + formulas. Values are conservative copper references for
//  planning only — NOT a substitute for an electrician's calculations.
//

import Foundation

enum ElectricalReference {

    /// Standard miniature circuit breaker ratings (A).
    static let standardBreakers: [Int] = [6, 10, 16, 20, 25, 32, 40, 50, 63]

    /// Standard cable cross-sections (mm²).
    static let standardAreas: [Double] = [1.5, 2.5, 4, 6, 10, 16, 25]

    /// Conservative copper ampacity (A) by cross-section (mm²),
    /// single-phase, reference installation method.
    static let ampacity: [(area: Double, amps: Double)] = [
        (1.5, 16), (2.5, 25), (4, 32), (6, 40),
        (10, 50), (16, 63), (25, 80)
    ]

    /// Smallest standard breaker whose rating is >= current.
    static func recommendedBreaker(forCurrent current: Double) -> Int {
        standardBreakers.first(where: { Double($0) >= current }) ?? standardBreakers.last!
    }

    /// Smallest cross-section whose ampacity is >= the breaker rating.
    static func recommendedArea(forBreaker rating: Int) -> Double {
        ampacity.first(where: { $0.amps >= Double(rating) })?.area ?? standardAreas.last!
    }

    /// Smallest cross-section whose ampacity is >= the current.
    static func recommendedArea(forCurrent current: Double) -> Double {
        ampacity.first(where: { $0.amps >= current })?.area ?? standardAreas.last!
    }

    /// Ampacity (A) for a given cross-section, or 0 if unknown.
    static func ampacity(forArea area: Double) -> Double {
        ampacity.first(where: { abs($0.area - area) < 0.01 })?.amps ?? 0
    }

    /// Single-phase voltage drop in volts.
    /// ΔU = 2 · ρ · L · I / A
    static func voltageDrop(current: Double, length: Double,
                            area: Double, cable: CableType) -> Double {
        guard area > 0 else { return 0 }
        return 2 * cable.resistivity * length * current / area
    }

    /// Voltage drop as a percentage of supply voltage.
    static func voltageDropPercent(current: Double, length: Double, area: Double,
                                   cable: CableType, voltage: Int) -> Double {
        guard voltage > 0 else { return 0 }
        let drop = voltageDrop(current: current, length: length, area: area, cable: cable)
        return drop / Double(voltage) * 100
    }

    /// Friendly label for a cross-section.
    static func areaLabel(_ area: Double) -> String {
        if area == area.rounded() { return String(format: "%.0f mm²", area) }
        return String(format: "%.1f mm²", area)
    }
}
