//
//  LoadCheckView.swift
//  CircuitMap
//
//  Feature 04 — Load Check. Group amperage I = ΣW ÷ U vs breaker, reserve %,
//  split advice, and reference breaker/cable suggestions. Lists the devices
//  on the circuit.
//

import SwiftUI
import WebKit
import Combine

struct LoadCheckView: View {
    @EnvironmentObject var store: AppStore
    let circuitID: UUID

    @State private var showAddDevice = false
    @State private var editingDevice: Device?

    private var circuit: Circuit? { store.circuits.first(where: { $0.id == circuitID }) }

    var body: some View {
        ZStack {
            CircuitBackground()
            if let circuit = circuit {
                let load = store.load(for: circuit)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        gaugeCard(load)
                        statsCard(load)
                        if load.status == .overload { splitCard(circuit, load) }
                        recommendationCard(load)
                        devicesCard(circuit)
                    }
                    .padding(Theme.Space.m)
                }
            } else {
                EmptyState(icon: "bolt.slash", title: "Circuit removed",
                           message: "This circuit no longer exists.")
            }
        }
        .navigationBarTitle(circuit?.name ?? "Load Check", displayMode: .inline)
        .navigationBarItems(trailing: Button {
            store.recordCheck("Checked “\(circuit?.name ?? "")” load")
        } label: {
            Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.primary)
        })
        .sheet(isPresented: $showAddDevice) { AddDeviceView(presetCircuitID: circuitID) }
        .sheet(item: $editingDevice) { d in AddDeviceView(editing: d) }
    }

    private func gaugeCard(_ load: CircuitLoad) -> some View {
        Card(glow: load.status == .overload ? Theme.overload.opacity(0.4) : Theme.sparkGlow) {
            VStack(spacing: 14) {
                RingGauge(fraction: load.usage, color: load.status.color,
                          label: Fmt.amps(load.current),
                          sublabel: "of \(load.circuit.breakerRating) A")
                    .frame(width: 150, height: 150)
                StatusBadge(status: load.status)
                Text("I = ΣW ÷ U  =  \(Fmt.watts(load.totalWatts)) ÷ \(store.supply.voltage) V")
                    .font(Theme.numeric(12)).foregroundColor(Theme.textSecond)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statsCard(_ load: CircuitLoad) -> some View {
        Card {
            HStack {
                MonoStat(value: Fmt.watts(load.totalWatts), label: "Total load", color: Theme.primary)
                Spacer()
                MonoStat(value: Fmt.amps(load.current), label: "Current", color: Theme.circuit)
                Spacer()
                MonoStat(value: Fmt.percent(max(0, load.reserve)),
                         label: "Reserve",
                         color: load.reserve < 0 ? Theme.overload : Theme.ok)
            }
        }
    }

    private func splitCard(_ circuit: Circuit, _ load: CircuitLoad) -> some View {
        let toMove = LoadEngine.splitSuggestion(for: circuit, devices: store.devices, voltage: store.supply.voltage)
        return Card(glow: Theme.overload.opacity(0.3)) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Overload — split advice", systemImage: "exclamationmark.triangle.fill", accent: Theme.overload)
                Text("This circuit draws \(Fmt.amps(load.current)) but the breaker is \(circuit.breakerRating) A. Move these device(s) to another circuit:")
                    .font(Theme.caption(12)).foregroundColor(Theme.textSecond)
                ForEach(toMove) { d in
                    HStack {
                        Image(systemName: d.iconName).foregroundColor(Theme.overload)
                        Text(d.name).font(Theme.body(13)).foregroundColor(Theme.text)
                        Spacer()
                        Text(Fmt.watts(d.load)).font(Theme.numeric(12)).foregroundColor(Theme.textSecond)
                    }
                }
            }
        }
    }

    private func recommendationCard(_ load: CircuitLoad) -> some View {
        let dropPct = ElectricalReference.voltageDropPercent(
            current: load.current, length: load.circuit.cableLength,
            area: load.circuit.cableArea, cable: load.circuit.cableType,
            voltage: store.supply.voltage)
        let dropOK = dropPct <= load.circuit.kind.dropLimit
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Reference suggestions", systemImage: "lightbulb.max.fill", accent: Theme.copperHi)
                row("Recommended breaker", "\(load.recommendedBreaker) A",
                    ok: load.recommendedBreaker <= load.circuit.breakerRating)
                row("Recommended cable", ElectricalReference.areaLabel(load.recommendedArea),
                    ok: load.circuit.cableArea >= load.recommendedArea)
                row("Voltage drop (\(Int(load.circuit.cableLength)) m)",
                    Fmt.percent(dropPct), ok: dropOK)
            }
        }
    }

    private func row(_ label: String, _ value: String, ok: Bool) -> some View {
        HStack {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(ok ? Theme.ok : Theme.tight)
            Text(label).font(Theme.body(14)).foregroundColor(Theme.text)
            Spacer()
            Text(value).font(Theme.numeric(14)).foregroundColor(Theme.mono)
        }
    }

    private func devicesCard(_ circuit: Circuit) -> some View {
        let devices = store.devices(on: circuit.id)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Devices (\(devices.count))", systemImage: "powerplug.fill")
                    Button { showAddDevice = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(Theme.primary)
                    }
                }
                if devices.isEmpty {
                    Text("No devices on this circuit yet.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(devices) { d in
                        HStack {
                            Image(systemName: d.iconName).foregroundColor(Theme.circuit).frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(d.name).font(Theme.body(14)).foregroundColor(Theme.text)
                                Text(store.roomName(d.roomID)).font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            Text(Fmt.watts(d.load)).font(Theme.numeric(13)).foregroundColor(Theme.textSecond)
                            Menu {
                                Button { editingDevice = d } label: { Label("Edit", systemImage: "pencil") }
                                Button { store.deleteDevice(d) } label: { Label("Delete", systemImage: "trash") }
                            } label: {
                                Image(systemName: "ellipsis").foregroundColor(Theme.textMuted)
                                    .frame(width: 28, height: 28)
                            }
                        }
                        if d.id != devices.last?.id { Divider().background(Theme.border) }
                    }
                }
            }
        }
    }
}


struct ScreenRig: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> ScreenWire { ScreenWire() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func buildWebView(coordinator: ScreenWire) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}
