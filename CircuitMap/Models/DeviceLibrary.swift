//
//  DeviceLibrary.swift
//  CircuitMap
//
//  Catalog of typical household appliances with reference wattages.
//

import Foundation

struct DevicePreset: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let watts: Double
    let icon: String
    let kind: CircuitKind
    /// Suggested utilisation / demand factor.
    let demand: Double
}

enum DeviceLibrary {
    static let presets: [DevicePreset] = [
        DevicePreset(name: "LED lights", watts: 120, icon: "lightbulb.fill", kind: .lighting, demand: 1.0),
        DevicePreset(name: "Socket group", watts: 600, icon: "poweroutlet.type.b.fill", kind: .socket, demand: 0.6),
        DevicePreset(name: "Refrigerator", watts: 250, icon: "refrigerator.fill", kind: .socket, demand: 0.8),
        DevicePreset(name: "Microwave", watts: 1200, icon: "microwave.fill", kind: .socket, demand: 0.7),
        DevicePreset(name: "Electric kettle", watts: 2200, icon: "cup.and.saucer.fill", kind: .socket, demand: 0.5),
        DevicePreset(name: "Dishwasher", watts: 2000, icon: "dishwasher.fill", kind: .power, demand: 0.7),
        DevicePreset(name: "Washing machine", watts: 2100, icon: "washer.fill", kind: .power, demand: 0.7),
        DevicePreset(name: "Tumble dryer", watts: 2500, icon: "dryer.fill", kind: .power, demand: 0.7),
        DevicePreset(name: "Oven", watts: 3000, icon: "oven.fill", kind: .power, demand: 0.8),
        DevicePreset(name: "Induction hob", watts: 7000, icon: "stove.fill", kind: .power, demand: 0.6),
        DevicePreset(name: "Water heater", watts: 2000, icon: "drop.fill", kind: .power, demand: 0.9),
        DevicePreset(name: "Air conditioner", watts: 1500, icon: "air.conditioner.horizontal.fill", kind: .power, demand: 0.9),
        DevicePreset(name: "TV", watts: 150, icon: "tv.fill", kind: .socket, demand: 0.8),
        DevicePreset(name: "Desktop PC", watts: 450, icon: "desktopcomputer", kind: .socket, demand: 0.8),
        DevicePreset(name: "Toaster", watts: 900, icon: "flame.fill", kind: .socket, demand: 0.4),
        DevicePreset(name: "Vacuum cleaner", watts: 1400, icon: "wind", kind: .socket, demand: 0.4),
        DevicePreset(name: "Hair dryer", watts: 1800, icon: "hands.and.sparkles.fill", kind: .socket, demand: 0.3),
        DevicePreset(name: "Heater", watts: 2000, icon: "heater.vertical.fill", kind: .power, demand: 0.9)
    ]
}
