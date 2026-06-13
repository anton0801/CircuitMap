//
//  AppStore.swift
//  CircuitMap
//
//  Single source of truth. Holds AppData, exposes CRUD, logs history,
//  and surfaces derived load calculations via LoadEngine.
//

import SwiftUI
import Combine

final class AppStore: ObservableObject {
    @Published var data: AppData {
        didSet { persistence.save(data) }
    }

    private let persistence = PersistenceManager.shared

    init() {
        if let loaded = persistence.load() {
            self.data = loaded
        } else {
            // First ever launch: open with a populated sample so the board
            // isn't empty. Onboarding then customizes supply / rooms.
            self.data = SampleData.make()
        }
    }

    // MARK: - Supply

    var supply: Supply { data.supply }
    func updateSupply(_ s: Supply) { data.supply = s }

    // MARK: - Circuits

    var circuits: [Circuit] { data.circuits }

    func addCircuit(_ c: Circuit) {
        data.circuits.append(c)
        log(.added, "Circuit “\(c.name)” (\(c.breakerRating) A)")
    }
    func updateCircuit(_ c: Circuit) {
        if let i = data.circuits.firstIndex(where: { $0.id == c.id }) {
            data.circuits[i] = c
            log(.edited, "Circuit “\(c.name)”")
        }
    }
    func deleteCircuit(_ c: Circuit) {
        // Detach devices and points from the removed circuit.
        for i in data.devices.indices where data.devices[i].circuitID == c.id {
            data.devices[i].circuitID = nil
        }
        for i in data.points.indices where data.points[i].circuitID == c.id {
            data.points[i].circuitID = nil
        }
        data.circuits.removeAll { $0.id == c.id }
        log(.removed, "Circuit “\(c.name)”")
    }

    // MARK: - Devices

    var devices: [Device] { data.devices }

    func devices(on circuitID: UUID) -> [Device] {
        data.devices.filter { $0.circuitID == circuitID }
    }
    func devices(in roomID: UUID) -> [Device] {
        data.devices.filter { $0.roomID == roomID }
    }
    func addDevice(_ d: Device) {
        data.devices.append(d)
        log(.added, "Device “\(d.name)” (\(Int(d.watts)) W)")
    }
    func updateDevice(_ d: Device) {
        if let i = data.devices.firstIndex(where: { $0.id == d.id }) {
            data.devices[i] = d
            log(.edited, "Device “\(d.name)”")
        }
    }
    func deleteDevice(_ d: Device) {
        data.devices.removeAll { $0.id == d.id }
        log(.removed, "Device “\(d.name)”")
    }

    // MARK: - Rooms

    var rooms: [Room] { data.rooms }

    func addRoom(_ r: Room) {
        data.rooms.append(r)
        log(.added, "Room “\(r.name)”")
    }
    func updateRoom(_ r: Room) {
        if let i = data.rooms.firstIndex(where: { $0.id == r.id }) { data.rooms[i] = r }
    }
    func deleteRoom(_ r: Room) {
        data.points.removeAll { $0.roomID == r.id }
        for i in data.devices.indices where data.devices[i].roomID == r.id {
            data.devices[i].roomID = nil
        }
        data.rooms.removeAll { $0.id == r.id }
        log(.removed, "Room “\(r.name)”")
    }
    func roomName(_ id: UUID?) -> String {
        guard let id = id else { return "Unassigned" }
        return data.rooms.first(where: { $0.id == id })?.name ?? "Unassigned"
    }
    func circuitName(_ id: UUID?) -> String {
        guard let id = id else { return "No circuit" }
        return data.circuits.first(where: { $0.id == id })?.name ?? "No circuit"
    }

    // MARK: - Socket points

    var points: [SocketPoint] { data.points }
    func points(in roomID: UUID) -> [SocketPoint] {
        data.points.filter { $0.roomID == roomID }
    }
    func addPoint(_ p: SocketPoint) { data.points.append(p) }
    func updatePoint(_ p: SocketPoint) {
        if let i = data.points.firstIndex(where: { $0.id == p.id }) { data.points[i] = p }
    }
    func deletePoint(_ p: SocketPoint) { data.points.removeAll { $0.id == p.id } }

    // MARK: - Safety notes

    var notes: [SafetyNote] { data.notes }
    func addNote(_ n: SafetyNote) { data.notes.append(n) }
    func updateNote(_ n: SafetyNote) {
        if let i = data.notes.firstIndex(where: { $0.id == n.id }) { data.notes[i] = n }
    }
    func deleteNote(_ n: SafetyNote) { data.notes.removeAll { $0.id == n.id } }

    // MARK: - Photos

    var photos: [PhotoMarker] { data.photos }
    func addPhoto(_ p: PhotoMarker) { data.photos.insert(p, at: 0) }
    func deletePhoto(_ p: PhotoMarker) {
        PhotoStore.shared.delete(p.imageRef)
        data.photos.removeAll { $0.id == p.id }
    }

    // MARK: - Reminders

    var reminders: [Reminder] { data.reminders }
    func addReminder(_ r: Reminder) {
        data.reminders.append(r)
        NotificationManager.shared.schedule(r)
    }
    func updateReminder(_ r: Reminder) {
        if let i = data.reminders.firstIndex(where: { $0.id == r.id }) {
            data.reminders[i] = r
            NotificationManager.shared.cancel(r)
            if r.enabled { NotificationManager.shared.schedule(r) }
        }
    }
    func deleteReminder(_ r: Reminder) {
        NotificationManager.shared.cancel(r)
        data.reminders.removeAll { $0.id == r.id }
    }

    // MARK: - Prices

    var prices: PriceBook { data.prices }
    func updatePrices(_ p: PriceBook) { data.prices = p }

    // MARK: - History

    var history: [HistoryEvent] { data.history.sorted { $0.date > $1.date } }
    func log(_ kind: HistoryKind, _ detail: String) {
        data.history.append(HistoryEvent(kind: kind, detail: detail))
        if data.history.count > 200 { data.history.removeFirst(data.history.count - 200) }
    }
    func clearHistory() { data.history.removeAll() }

    // MARK: - Derived (LoadEngine)

    func loads() -> [CircuitLoad] {
        LoadEngine.allLoads(circuits: data.circuits, devices: data.devices, voltage: data.supply.voltage)
    }
    func load(for circuit: Circuit) -> CircuitLoad {
        LoadEngine.circuitLoad(circuit, devices: data.devices, voltage: data.supply.voltage)
    }
    func houseTotals() -> HouseTotals {
        LoadEngine.houseTotals(circuits: data.circuits, devices: data.devices, supply: data.supply)
    }
    func phaseBalance() -> [LegLoad] {
        LoadEngine.phaseBalance(circuits: data.circuits, devices: data.devices)
    }
    var overloadCount: Int { loads().filter { $0.status == .overload }.count }

    /// Builds (does not apply) an auto-balance plan.
    func balancePlan() -> BalancePlan {
        LoadEngine.autoBalance(circuits: data.circuits, devices: data.devices, voltage: data.supply.voltage)
    }
    /// Applies a balance plan and records history.
    func applyBalance(_ plan: BalancePlan) {
        guard plan.hasChanges else { return }
        data.devices = plan.updatedDevices
        log(.balanced, "Auto-balanced \(plan.moves.count) device(s)")
    }

    func recordCheck(_ detail: String) { log(.checked, detail) }

    // MARK: - Lifecycle

    func flush() { persistence.flush(data) }

    func loadSample() {
        data = SampleData.make()
        log(.added, "Loaded sample data")
    }
    func wipeAll() {
        for p in data.photos { PhotoStore.shared.delete(p.imageRef) }
        NotificationManager.shared.cancelAll()
        var fresh = AppData()
        fresh.supply = data.supply // keep supply configuration
        data = fresh
    }
}
