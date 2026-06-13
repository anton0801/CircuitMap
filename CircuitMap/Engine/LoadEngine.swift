//
//  LoadEngine.swift
//  CircuitMap
//
//  Pure-function load calculation engine. This is the heart of the app:
//  per-circuit load vs breaker rating, overload detection, auto-balance,
//  house totals and phase balance. No SwiftUI / no side effects.
//

import Foundation

// MARK: - Result types

struct CircuitLoad: Identifiable {
    let id: UUID
    let circuit: Circuit
    let totalWatts: Double
    let current: Double          // A
    let reserve: Double          // %  (can be negative on overload)
    let status: LoadStatus
    let deviceCount: Int

    /// Fraction of breaker capacity used (0...n).
    var usage: Double {
        guard circuit.breakerRating > 0 else { return 0 }
        return current / Double(circuit.breakerRating)
    }
    var recommendedBreaker: Int { ElectricalReference.recommendedBreaker(forCurrent: current) }
    var recommendedArea: Double { ElectricalReference.recommendedArea(forCurrent: current) }
}

struct HouseTotals {
    let totalWatts: Double
    let totalCurrent: Double
    let capacityWatts: Double
    let headroom: Double         // %
    let overloadCount: Int
    var isOverCapacity: Bool { totalWatts > capacityWatts }
}

struct LegLoad: Identifiable {
    let id = UUID()
    let leg: PhaseLeg
    let watts: Double
}

struct BalanceMove: Identifiable {
    let id = UUID()
    let device: Device
    let fromCircuit: String
    let toCircuit: String
}

struct BalancePlan {
    let updatedDevices: [Device]   // devices with new circuitID assignments
    let moves: [BalanceMove]
    var hasChanges: Bool { !moves.isEmpty }
}

// MARK: - Engine

enum LoadEngine {

    // Thresholds
    static let tightReserve: Double = 15.0   // % below which a circuit is "low margin"

    /// Devices assigned to a circuit.
    static func devices(on circuitID: UUID, in devices: [Device]) -> [Device] {
        devices.filter { $0.circuitID == circuitID }
    }

    /// Total effective load (W) on a circuit.
    static func load(on circuit: Circuit, devices: [Device]) -> Double {
        self.devices(on: circuit.id, in: devices).reduce(0) { $0 + $1.load }
    }

    /// Full computed load for a circuit.
    static func circuitLoad(_ circuit: Circuit, devices: [Device], voltage: Int) -> CircuitLoad {
        let assigned = self.devices(on: circuit.id, in: devices)
        let watts = assigned.reduce(0) { $0 + $1.load }
        let v = max(voltage, 1)
        let current = watts / Double(v)
        let rating = Double(max(circuit.breakerRating, 1))
        let reserve = (rating - current) / rating * 100

        let status: LoadStatus
        if current > rating { status = .overload }
        else if reserve < tightReserve { status = .tight }
        else { status = .ok }

        return CircuitLoad(id: circuit.id, circuit: circuit, totalWatts: watts,
                           current: current, reserve: reserve, status: status,
                           deviceCount: assigned.count)
    }

    static func allLoads(circuits: [Circuit], devices: [Device], voltage: Int) -> [CircuitLoad] {
        circuits.map { circuitLoad($0, devices: devices, voltage: voltage) }
    }

    // MARK: House totals

    static func houseTotals(circuits: [Circuit], devices: [Device], supply: Supply) -> HouseTotals {
        let loads = allLoads(circuits: circuits, devices: devices, voltage: supply.voltage)
        let totalWatts = loads.reduce(0) { $0 + $1.totalWatts }
        let v = max(supply.voltage, 1)
        let totalCurrent = totalWatts / Double(v)
        // Capacity = mainBreaker × voltage × legs
        let capacity = Double(supply.mainBreaker) * Double(v) * Double(supply.phase.legCount)
        let headroom = capacity > 0 ? (capacity - totalWatts) / capacity * 100 : 0
        let overloads = loads.filter { $0.status == .overload }.count
        return HouseTotals(totalWatts: totalWatts, totalCurrent: totalCurrent,
                           capacityWatts: capacity, headroom: headroom, overloadCount: overloads)
    }

    // MARK: Phase balance (3-phase)

    static func phaseBalance(circuits: [Circuit], devices: [Device]) -> [LegLoad] {
        PhaseLeg.allCases.map { leg in
            let watts = circuits
                .filter { $0.leg == leg }
                .reduce(0.0) { $0 + load(on: $1, devices: devices) }
            return LegLoad(leg: leg, watts: watts)
        }
    }

    /// Imbalance % = (max - min) / max across the three legs.
    static func imbalancePercent(_ legs: [LegLoad]) -> Double {
        let values = legs.map { $0.watts }
        guard let maxV = values.max(), maxV > 0, let minV = values.min() else { return 0 }
        return (maxV - minV) / maxV * 100
    }

    // MARK: Auto-balance

    /// Greedy redistribution: move devices off overloaded circuits onto the
    /// same-kind circuit with the most spare headroom (in watts).
    /// Returns a plan (devices with reassigned circuitIDs) without mutating input.
    static func autoBalance(circuits: [Circuit], devices: [Device], voltage: Int) -> BalancePlan {
        var working = devices
        var moves: [BalanceMove] = []
        let v = max(voltage, 1)

        // Capacity in watts per circuit.
        func capacity(_ c: Circuit) -> Double { Double(c.breakerRating) * Double(v) }
        func currentLoad(_ cid: UUID) -> Double {
            working.filter { $0.circuitID == cid }.reduce(0) { $0 + $1.load }
        }
        func headroom(_ c: Circuit) -> Double { capacity(c) - currentLoad(c.id) }

        let circuitsByKind = Dictionary(grouping: circuits, by: { $0.kind })

        // Process overloaded circuits, heaviest device first.
        var didMove = true
        var safety = 0
        while didMove && safety < 200 {
            didMove = false
            safety += 1

            for circuit in circuits {
                let cap = capacity(circuit)
                guard currentLoad(circuit.id) > cap else { continue }

                // candidate devices on this circuit, heaviest first
                let onCircuit = working
                    .filter { $0.circuitID == circuit.id }
                    .sorted { $0.load > $1.load }

                for dev in onCircuit {
                    // stop once this circuit is within capacity
                    if currentLoad(circuit.id) <= cap { break }

                    // find best same-kind target with room for this device
                    let candidates = (circuitsByKind[circuit.kind] ?? [])
                        .filter { $0.id != circuit.id }
                        .filter { headroom($0) >= dev.load }
                        .sorted { headroom($0) > headroom($1) }

                    guard let target = candidates.first else { continue }

                    if let idx = working.firstIndex(where: { $0.id == dev.id }) {
                        let fromName = circuit.name
                        working[idx].circuitID = target.id
                        moves.append(BalanceMove(device: working[idx],
                                                 fromCircuit: fromName,
                                                 toCircuit: target.name))
                        didMove = true
                    }
                }
            }
        }

        return BalancePlan(updatedDevices: working, moves: moves)
    }

    /// Which devices to move off an overloaded circuit to bring it within rating
    /// (advice for the Load Check screen — does not mutate).
    static func splitSuggestion(for circuit: Circuit, devices: [Device], voltage: Int) -> [Device] {
        let v = max(voltage, 1)
        let cap = Double(circuit.breakerRating) * Double(v)
        var load = self.load(on: circuit, devices: devices)
        guard load > cap else { return [] }

        var toMove: [Device] = []
        let sorted = self.devices(on: circuit.id, in: devices).sorted { $0.load > $1.load }
        for dev in sorted {
            if load <= cap { break }
            toMove.append(dev)
            load -= dev.load
        }
        return toMove
    }
}
