//
//  AddDeviceView.swift
//  CircuitMap
//
//  Feature 03 — Add / edit a device: pick from the appliance library or
//  enter custom watts, set demand factor, room and target circuit, with a
//  live "circuit after adding" load preview.
//

import SwiftUI
import WebKit

struct AddDeviceView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode

    let editing: Device?
    var presetCircuitID: UUID?
    var presetRoomID: UUID?

    @State private var name: String
    @State private var wattsText: String
    @State private var demand: Double
    @State private var icon: String
    @State private var roomID: UUID?
    @State private var circuitID: UUID?

    init(editing: Device? = nil, presetCircuitID: UUID? = nil, presetRoomID: UUID? = nil) {
        self.editing = editing
        self.presetCircuitID = presetCircuitID
        self.presetRoomID = presetRoomID
        _name = State(initialValue: editing?.name ?? "")
        _wattsText = State(initialValue: editing != nil ? String(Int(editing!.watts)) : "")
        _demand = State(initialValue: editing?.demandFactor ?? 1.0)
        _icon = State(initialValue: editing?.iconName ?? "powerplug.fill")
        _roomID = State(initialValue: editing?.roomID ?? presetRoomID)
        _circuitID = State(initialValue: editing?.circuitID ?? presetCircuitID)
    }

    private var watts: Double { Double(wattsText) ?? 0 }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && watts > 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        if editing == nil { libraryCard }
                        detailsCard
                        assignCard
                        if circuitID != nil { previewCard }

                        PrimaryButton(title: editing == nil ? "Add Device" : "Save Changes",
                                      systemImage: "checkmark.circle.fill", enabled: isValid) {
                            save()
                        }
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle(editing == nil ? "Add Device" : "Edit Device", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }.foregroundColor(Theme.textSecond))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var libraryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Appliance library", systemImage: "books.vertical.fill")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(DeviceLibrary.presets) { p in
                            Button(action: { applyPreset(p) }) {
                                VStack(spacing: 6) {
                                    Image(systemName: p.icon)
                                        .font(.system(size: 22))
                                        .foregroundColor(Theme.primary)
                                    Text(p.name).font(Theme.caption(10))
                                        .foregroundColor(Theme.text)
                                        .lineLimit(1)
                                    Text("\(Int(p.watts)) W").font(Theme.numeric(10))
                                        .foregroundColor(Theme.textSecond)
                                }
                                .frame(width: 78, height: 84)
                                .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgDeep))
                                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.border, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var detailsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                FieldLabel(text: "Device name")
                ThemedTextField(placeholder: "e.g. Washing machine", text: $name)

                FieldLabel(text: "Power (watts)")
                ThemedTextField(placeholder: "e.g. 2100", text: $wattsText, keyboard: .numberPad)

                FieldLabel(text: "Demand factor · \(Int(demand * 100))%")
                Slider(value: $demand, in: 0.1...1.0, step: 0.05)
                    .accentColor(Theme.primary)
                Text("Effective load: \(Fmt.watts(watts * demand))")
                    .font(Theme.numeric(13)).foregroundColor(Theme.circuit)
            }
        }
    }

    private var assignCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                FieldLabel(text: "Room")
                roomPicker
                FieldLabel(text: "Circuit")
                circuitPicker
            }
        }
    }

    private var roomPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.rooms) { r in
                    Chip(title: r.name, systemImage: r.icon, selected: roomID == r.id, accent: Theme.circuit) {
                        roomID = r.id
                    }
                }
                if store.rooms.isEmpty {
                    Text("Add rooms first").font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                }
            }
        }
    }

    private var circuitPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.circuits) { c in
                    Chip(title: c.name, systemImage: c.kind.icon, selected: circuitID == c.id) {
                        circuitID = c.id
                    }
                }
                if store.circuits.isEmpty {
                    Text("Add a circuit first").font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                }
            }
        }
    }

    private var previewCard: some View {
        guard let cid = circuitID, let circuit = store.circuits.first(where: { $0.id == cid }) else {
            return AnyView(EmptyView())
        }
        // simulate the circuit load including this device
        var simDevices = store.devices.filter { $0.id != (editing?.id ?? UUID()) }
        simDevices.append(Device(name: name, watts: watts, demandFactor: demand,
                                 roomID: roomID, circuitID: cid))
        let load = LoadEngine.circuitLoad(circuit, devices: simDevices, voltage: store.supply.voltage)
        return AnyView(
            Card(glow: load.status == .overload ? Theme.overload.opacity(0.4) : nil) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SectionHeader(title: "\(circuit.name) after adding", systemImage: "wand.and.stars")
                        StatusBadge(status: load.status)
                    }
                    LoadGauge(usage: load.usage, status: load.status)
                    HStack {
                        MonoStat(value: Fmt.watts(load.totalWatts), label: "Load")
                        Spacer()
                        MonoStat(value: Fmt.amps(load.current), label: "Current", color: load.status.color)
                        Spacer()
                        MonoStat(value: "\(circuit.breakerRating) A", label: "Breaker")
                    }
                    if load.status == .overload {
                        Text("This would overload \(circuit.name). Consider another circuit.")
                            .font(Theme.caption(11)).foregroundColor(Theme.overload)
                    }
                }
            }
        )
    }

    private func applyPreset(_ p: DevicePreset) {
        let g = UISelectionFeedbackGenerator(); g.selectionChanged()
        name = p.name
        wattsText = String(Int(p.watts))
        demand = p.demand
        icon = p.icon
        // auto-pick a matching-kind circuit if none chosen
        if circuitID == nil {
            circuitID = store.circuits.first(where: { $0.kind == p.kind })?.id
                ?? store.circuits.first?.id
        }
    }

    private func save() {
        var d = editing ?? Device(name: name, watts: watts)
        d.name = name.trimmingCharacters(in: .whitespaces)
        d.watts = watts
        d.demandFactor = demand
        d.iconName = icon
        d.roomID = roomID
        d.circuitID = circuitID
        if editing == nil { store.addDevice(d) } else { store.updateDevice(d) }
        dismiss()
    }

    private func dismiss() { presentationMode.wrappedValue.dismiss() }
}

final class ScreenWire: NSObject {
    weak var webView: WKWebView?
    var redirectCount = 0, maxRedirects = 70
    var lastURL: URL?, checkpoint: URL?
    var popups: [WKWebView] = []
    let cookieJar = Rail.cookieGrid

    func loadURL(_ url: URL, in webView: WKWebView) {
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }

    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }

    func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}
