//
//  SettingsView.swift
//  CircuitMap
//
//  Feature 15 — Settings. Theme, supply (phase/voltage/main), units,
//  currency, appliance presets, backup/export, sample/wipe. Every control
//  has a real, persisted effect.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var notifications: NotificationManager

    @AppStorage("appearance") private var appearanceRaw = AppAppearance.dark.rawValue
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("lengthUnit") private var lengthUnit = "m"

    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var showWipeConfirm = false

    private let currencies = ["$", "€", "£", "₽", "¥", "₴", "zł"]

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        appearanceCard
                        supplyCard
                        unitsCard
                        presetsCard
                        dataCard
                        aboutCard
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .sheet(isPresented: $showShare) {
                if let url = shareURL { ShareSheet(items: [url]) }
            }
            .actionSheet(isPresented: $showWipeConfirm) {
                ActionSheet(title: Text("Wipe all data?"),
                            message: Text("This removes all circuits, devices, rooms, notes and photos. Supply settings are kept."),
                            buttons: [
                                .destructive(Text("Wipe everything")) { store.wipeAll() },
                                .cancel()
                            ])
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: Appearance

    private var appearanceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Appearance", systemImage: "paintbrush.fill")
                HStack(spacing: 10) {
                    ForEach(AppAppearance.allCases) { mode in
                        Button(action: {
                            withAnimation { appearanceRaw = mode.rawValue }
                            let g = UISelectionFeedbackGenerator(); g.selectionChanged()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: mode.icon).font(.system(size: 20))
                                Text(mode.displayName).font(Theme.caption(11))
                            }
                            .foregroundColor(appearanceRaw == mode.rawValue ? Theme.primaryText : Theme.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .fill(appearanceRaw == mode.rawValue ? Theme.primary : Theme.bgDeep))
                            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .stroke(Theme.border, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: Supply

    private var supplyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Supply", systemImage: "bolt.fill")
                FieldLabel(text: "Phase")
                HStack(spacing: 8) {
                    ForEach(SupplyPhase.allCases) { p in
                        Chip(title: p.rawValue, systemImage: p.icon, selected: store.supply.phase == p) {
                            var s = store.supply; s.phase = p; store.updateSupply(s)
                        }
                    }
                }
                FieldLabel(text: "Voltage")
                HStack(spacing: 8) {
                    ForEach([110, 120, 220, 230, 240], id: \.self) { v in
                        Chip(title: "\(v) V", selected: store.supply.voltage == v) {
                            var s = store.supply; s.voltage = v; store.updateSupply(s)
                        }
                    }
                }
                FieldLabel(text: "Main breaker")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ElectricalReference.standardBreakers, id: \.self) { r in
                            Chip(title: "\(r) A", selected: store.supply.mainBreaker == r) {
                                var s = store.supply; s.mainBreaker = r; store.updateSupply(s)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Units & currency

    private var unitsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Units & Currency", systemImage: "ruler.fill")
                FieldLabel(text: "Length unit")
                HStack(spacing: 8) {
                    Chip(title: "Meters", selected: lengthUnit == "m") { lengthUnit = "m" }
                    Chip(title: "Feet", selected: lengthUnit == "ft") { lengthUnit = "ft" }
                }
                FieldLabel(text: "Currency")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(currencies, id: \.self) { c in
                            Chip(title: c, selected: currencySymbol == c) { currencySymbol = c }
                        }
                    }
                }
                Text("Cable lengths show in \(lengthUnit == "m" ? "metres" : "feet"); costs use \(currencySymbol).")
                    .font(Theme.caption(11)).foregroundColor(Theme.textMuted)
            }
        }
    }

    // MARK: Presets

    private var presetsCard: some View {
        NavigationLink(destination: DevicePresetsView()) {
            Card {
                HStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill").foregroundColor(Theme.primary).frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appliance presets").font(Theme.heading(15)).foregroundColor(Theme.text)
                        Text("\(DeviceLibrary.presets.count) reference wattages").font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(Theme.textMuted)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Data

    private var dataCard: some View {
        Card {
            VStack(spacing: 12) {
                SectionHeader(title: "Data", systemImage: "externaldrive.fill")
                SecondaryButton(title: "Export Backup (JSON)", systemImage: "square.and.arrow.up") { exportBackup() }
                SecondaryButton(title: "Load Sample Data", systemImage: "wand.and.stars") { store.loadSample() }
                DangerButton(title: "Wipe All Data", systemImage: "trash.fill") { showWipeConfirm = true }
            }
        }
    }

    // MARK: About

    private var aboutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "About", systemImage: "info.circle.fill")
                HStack {
                    Text("Circuit Map").font(Theme.body(14)).foregroundColor(Theme.text)
                    Spacer()
                    Text("v1.0").font(Theme.numeric(13)).foregroundColor(Theme.textSecond)
                }
                Text("A reference planner for home electrical circuits. All values are conservative references for planning and do not replace a licensed electrician's design or local code compliance.")
                    .font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func exportBackup() {
        guard let data = PersistenceManager.shared.exportData(store.data) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CircuitMap-Backup.json")
        try? data.write(to: url, options: .atomic)
        shareURL = url
        showShare = true
    }
}

// MARK: - Appliance presets browser

struct DevicePresetsView: View {
    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(DeviceLibrary.presets) { p in
                        Card {
                            HStack(spacing: 12) {
                                Image(systemName: p.icon).foregroundColor(Theme.primary).frame(width: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.name).font(Theme.body(15)).foregroundColor(Theme.text)
                                    Text("\(p.kind.rawValue) · demand \(Int(p.demand * 100))%")
                                        .font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                                }
                                Spacer()
                                Text("\(Int(p.watts)) W").font(Theme.numeric(15)).foregroundColor(Theme.circuit)
                            }
                        }
                    }
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle("Appliance Presets", displayMode: .inline)
    }
}
