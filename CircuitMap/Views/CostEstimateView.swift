//
//  CostEstimateView.swift
//  CircuitMap
//
//  Feature 09 — Cost Estimate. Breakers, cable (by metreage and section)
//  and sockets/switches, with editable unit prices and the chosen currency.
//

import SwiftUI

struct CostEstimateView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("lengthUnit") private var lengthUnit = "m"
    @State private var showPrices = false

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            totalCard
            breakdownCard
            SecondaryButton(title: "Edit Unit Prices", systemImage: "slider.horizontal.3") {
                showPrices = true
            }
            DisclaimerBanner()
        }
        .sheet(isPresented: $showPrices) { PriceEditorSheet() }
    }

    // MARK: Calculations

    private var breakerCost: Double {
        Double(store.circuits.count) * store.prices.breakerEach
    }
    private var cableCost: Double {
        store.circuits.reduce(0) { sum, c in
            let key = ElectricalReference.areaLabel(c.cableArea)
                .replacingOccurrences(of: " mm²", with: "")
            let perM = store.prices.cablePerMetre[key] ?? 1.0
            return sum + c.cableLength * perM
        }
    }
    private var socketCount: Int {
        store.points.filter { $0.kind == .socket || $0.kind == .output }.reduce(0) { $0 + $1.count }
    }
    private var switchCount: Int {
        store.points.filter { $0.kind == .light }.reduce(0) { $0 + $1.count }
    }
    private var socketCost: Double { Double(socketCount) * store.prices.socketEach }
    private var switchCost: Double { Double(switchCount) * store.prices.switchEach }
    private var total: Double { breakerCost + cableCost + socketCost + switchCost }
    private var totalCableLength: Double { store.circuits.reduce(0) { $0 + $1.cableLength } }

    private var totalCard: some View {
        Card(glow: Theme.sparkGlow) {
            VStack(spacing: 6) {
                Text("Estimated materials").font(Theme.caption(12)).foregroundColor(Theme.textSecond)
                Text(Fmt.money(total, symbol: currencySymbol))
                    .font(Theme.numeric(38, weight: .heavy))
                    .foregroundColor(Theme.primary)
                    .shadow(color: Theme.sparkGlow, radius: 8)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var breakdownCard: some View {
        Card {
            VStack(spacing: 0) {
                row("Breakers", "\(store.circuits.count) × \(Fmt.money(store.prices.breakerEach, symbol: currencySymbol))", breakerCost)
                Divider().background(Theme.border)
                row("Cable", "\(Fmt.length(totalCableLength)) total", cableCost)
                Divider().background(Theme.border)
                row("Sockets / outputs", "\(socketCount) × \(Fmt.money(store.prices.socketEach, symbol: currencySymbol))", socketCost)
                Divider().background(Theme.border)
                row("Switches", "\(switchCount) × \(Fmt.money(store.prices.switchEach, symbol: currencySymbol))", switchCost)
            }
        }
    }

    private func row(_ title: String, _ detail: String, _ cost: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.body(14)).foregroundColor(Theme.text)
                Text(detail).font(Theme.caption(10)).foregroundColor(Theme.textMuted)
            }
            Spacer()
            Text(Fmt.money(cost, symbol: currencySymbol))
                .font(Theme.numeric(15)).foregroundColor(Theme.mono)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Price editor

struct PriceEditorSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("currencySymbol") private var currencySymbol = "$"

    @State private var breaker: String = ""
    @State private var socket: String = ""
    @State private var switchP: String = ""
    @State private var cable: [String: String] = [:]

    private let cableKeys = ["1.5", "2.5", "4", "6", "10", "16"]

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Components (\(currencySymbol))", systemImage: "shippingbox.fill")
                                priceField("Breaker each", $breaker)
                                priceField("Socket / output each", $socket)
                                priceField("Switch each", $switchP)
                            }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Cable per metre (\(currencySymbol))", systemImage: "cable.connector")
                                ForEach(cableKeys, id: \.self) { key in
                                    priceField("\(key) mm²", Binding(
                                        get: { cable[key] ?? "" },
                                        set: { cable[key] = $0 }))
                                }
                            }
                        }
                        PrimaryButton(title: "Save Prices", systemImage: "checkmark.circle.fill") { save() }
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Unit Prices", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(Theme.textSecond))
            .onAppear(perform: load)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func priceField(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label).font(Theme.body(14)).foregroundColor(Theme.text)
            Spacer()
            TextField("0", text: binding)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .font(Theme.numeric(15))
                .foregroundColor(Theme.mono)
                .frame(width: 80)
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgDeep))
        }
    }

    private func load() {
        let p = store.prices
        breaker = String(p.breakerEach)
        socket = String(p.socketEach)
        switchP = String(p.switchEach)
        for k in cableKeys { cable[k] = String(p.cablePerMetre[k] ?? 0) }
    }

    private func save() {
        var p = store.prices
        p.breakerEach = Double(breaker) ?? p.breakerEach
        p.socketEach = Double(socket) ?? p.socketEach
        p.switchEach = Double(switchP) ?? p.switchEach
        for k in cableKeys {
            if let v = Double(cable[k] ?? "") { p.cablePerMetre[k] = v }
        }
        store.updatePrices(p)
        presentationMode.wrappedValue.dismiss()
    }
}
