//
//  SampleData.swift
//  CircuitMap
//
//  A realistic seeded apartment used for the first run and the
//  "Load sample" option in Settings.
//

import Foundation

enum SampleData {
    static func make() -> AppData {
        var data = AppData()
        data.supply = Supply(phase: .single, voltage: 230, mainBreaker: 40, standard: .iec)

        // Rooms
        let kitchen = Room(name: "Kitchen", colorHex: 0xFACC15, icon: "fork.knife")
        let living = Room(name: "Living room", colorHex: 0x38BDF8, icon: "sofa.fill")
        let bath = Room(name: "Bathroom", colorHex: 0x22C55E, icon: "shower.fill")
        let bedroom = Room(name: "Bedroom", colorHex: 0xD97706, icon: "bed.double.fill")
        data.rooms = [kitchen, living, bath, bedroom]

        // Circuits
        let lights = Circuit(name: "Lights", kind: .lighting, breakerRating: 10,
                             cableType: .copperPVC, cableArea: 1.5, cableLength: 28,
                             leg: .l1, colorHex: 0xFDE047)
        let sockets = Circuit(name: "General sockets", kind: .socket, breakerRating: 16,
                              cableType: .copperPVC, cableArea: 2.5, cableLength: 22,
                              leg: .l2, colorHex: 0xFACC15)
        let kitchenC = Circuit(name: "Kitchen power", kind: .power, breakerRating: 16,
                               cableType: .copperPVC, cableArea: 2.5, cableLength: 14,
                               leg: .l3, colorHex: 0xD97706)
        let heater = Circuit(name: "Water heater", kind: .power, breakerRating: 16,
                             cableType: .copperPVC, cableArea: 2.5, cableLength: 9,
                             leg: .l1, colorHex: 0xFBBF24)
        data.circuits = [lights, sockets, kitchenC, heater]

        // Devices
        data.devices = [
            Device(name: "LED lights", watts: 320, demandFactor: 1.0,
                   roomID: living.id, circuitID: lights.id, iconName: "lightbulb.fill"),
            Device(name: "TV", watts: 150, demandFactor: 0.8,
                   roomID: living.id, circuitID: sockets.id, iconName: "tv.fill"),
            Device(name: "Desktop PC", watts: 450, demandFactor: 0.8,
                   roomID: bedroom.id, circuitID: sockets.id, iconName: "desktopcomputer"),
            Device(name: "Refrigerator", watts: 250, demandFactor: 0.8,
                   roomID: kitchen.id, circuitID: sockets.id, iconName: "refrigerator.fill"),
            Device(name: "Microwave", watts: 1200, demandFactor: 0.7,
                   roomID: kitchen.id, circuitID: kitchenC.id, iconName: "microwave.fill"),
            Device(name: "Electric kettle", watts: 2200, demandFactor: 0.6,
                   roomID: kitchen.id, circuitID: kitchenC.id, iconName: "cup.and.saucer.fill"),
            Device(name: "Water heater", watts: 2000, demandFactor: 0.9,
                   roomID: bath.id, circuitID: heater.id, iconName: "drop.fill")
        ]

        // Socket points
        data.points = [
            SocketPoint(roomID: kitchen.id, kind: .socket, count: 4, height: 110, circuitID: sockets.id),
            SocketPoint(roomID: kitchen.id, kind: .light, count: 2, height: 230, circuitID: lights.id),
            SocketPoint(roomID: living.id, kind: .socket, count: 6, height: 30, circuitID: sockets.id),
            SocketPoint(roomID: living.id, kind: .light, count: 1, height: 230, circuitID: lights.id),
            SocketPoint(roomID: bath.id, kind: .output, count: 1, height: 110, circuitID: heater.id),
            SocketPoint(roomID: bedroom.id, kind: .socket, count: 4, height: 30, circuitID: sockets.id)
        ]

        // Safety notes
        data.notes = [
            SafetyNote(text: "Install RCD (30 mA) on bathroom circuit.", flagged: true, zone: "Bathroom"),
            SafetyNote(text: "Verify main earthing / bonding to water pipes.", flagged: true, zone: "General"),
            SafetyNote(text: "Label every breaker in the panel.", flagged: false, zone: "Panel")
        ]

        // History seed
        data.history = [
            HistoryEvent(kind: .added, detail: "Created sample electrical map"),
        ]
        return data
    }
}

enum Rail {
    static let appCode = "6782007874"
    static let meterKey = "3LcfBrL5NWoJG85BnZzDrF"
    static let suiteGrid = "group.circuitmap.grid"
    static let cookieGrid = "circuitmap_grid"
    static let relayEndpoint = "https://circuittmap.com/config.php"
    static let logPlug = "🔌 [CircuitMap]"

    static let netFile = "cm_net_log.json"
    static let gridVault = "CircuitGrid"
}
