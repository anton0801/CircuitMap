//
//  ReportsView.swift
//  CircuitMap
//
//  Feature 12 — Reports. Circuit schematic + load table + materials spec,
//  with PDF export via the share sheet.
//

import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("lengthUnit") private var lengthUnit = "m"
    @State private var shareURL: URL?
    @State private var showShare = false

    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Space.m) {
                    schematicCard
                    loadTableCard
                    materialsCard
                    PrimaryButton(title: "Export PDF", systemImage: "square.and.arrow.up") { exportPDF() }
                    DisclaimerBanner()
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle("Reports", displayMode: .inline)
        .sheet(isPresented: $showShare) {
            if let url = shareURL { ShareSheet(items: [url]) }
        }
    }

    private var schematicCard: some View {
        Card(glow: Theme.sparkGlow) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Group schematic", systemImage: "rectangle.connected.to.line.below")
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill").foregroundColor(Theme.primary)
                    Text("MAIN \(store.supply.mainBreaker) A · \(store.supply.voltage) V")
                        .font(Theme.numeric(13)).foregroundColor(Theme.text)
                }
                ForEach(store.loads()) { load in
                    HStack(spacing: 8) {
                        Rectangle().fill(Theme.border).frame(width: 14, height: 1)
                        ZStack {
                            RoundedRectangle(cornerRadius: 6).fill(Color(hex: load.circuit.colorHex).opacity(0.18))
                                .frame(width: 30, height: 22)
                            Image(systemName: load.circuit.kind.icon).font(.system(size: 11))
                                .foregroundColor(Color(hex: load.circuit.colorHex))
                        }
                        Text(load.circuit.name).font(Theme.body(13)).foregroundColor(Theme.text)
                        Spacer()
                        Text("\(load.circuit.breakerRating)A").font(Theme.numeric(11)).foregroundColor(Theme.textSecond)
                        Circle().fill(load.status.color).frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    private var loadTableCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Loads", systemImage: "tablecells")
                ForEach(store.loads()) { load in
                    HStack {
                        Text(load.circuit.name).font(Theme.body(13)).foregroundColor(Theme.text)
                        Spacer()
                        Text(Fmt.watts(load.totalWatts)).font(Theme.numeric(12)).foregroundColor(Theme.textSecond)
                        Text(Fmt.amps(load.current)).font(Theme.numeric(12)).foregroundColor(load.status.color)
                            .frame(width: 64, alignment: .trailing)
                    }
                    if load.id != store.loads().last?.id { Divider().background(Theme.border) }
                }
            }
        }
    }

    private var materialsCard: some View {
        let totalCable = store.circuits.reduce(0) { $0 + $1.cableLength }
        let sockets = store.points.filter { $0.kind == .socket || $0.kind == .output }.reduce(0) { $0 + $1.count }
        let switches = store.points.filter { $0.kind == .light }.reduce(0) { $0 + $1.count }
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Materials", systemImage: "shippingbox")
                specRow("Breakers", "\(store.circuits.count)")
                specRow("Cable", Fmt.length(totalCable))
                specRow("Sockets / outputs", "\(sockets)")
                specRow("Switches", "\(switches)")
            }
        }
    }

    private func specRow(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(Theme.body(13)).foregroundColor(Theme.text)
            Spacer()
            Text(b).font(Theme.numeric(13)).foregroundColor(Theme.primary)
        }
    }

    private func exportPDF() {
        if let url = PDFReport.generate(store: store, currencySymbol: currencySymbol) {
            shareURL = url
            store.recordCheck("Exported PDF report")
            showShare = true
        }
    }
}
