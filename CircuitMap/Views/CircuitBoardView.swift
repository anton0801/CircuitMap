//
//  CircuitBoardView.swift
//  CircuitMap
//
//  Feature 01 — Circuit Board. Lists breaker groups with their load vs
//  rating, overloads in red. Add Circuit / Add Device / Auto-Balance /
//  Cable Advisor.
//

import SwiftUI

struct CircuitBoardView: View {
    @EnvironmentObject var store: AppStore

    @State private var showAddCircuit = false
    @State private var showAddDevice = false
    @State private var showBalance = false
    @State private var editingCircuit: Circuit?

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        summaryHeader
                        actionRow

                        if store.circuits.isEmpty {
                            Card {
                                EmptyState(icon: "bolt.square",
                                           title: "No circuits yet",
                                           message: "Add your first breaker group, then assign devices to it.")
                            }
                        } else {
                            ForEach(store.circuits) { circuit in
                                NavigationLink(destination: LoadCheckView(circuitID: circuit.id)) {
                                    CircuitRow(load: store.load(for: circuit))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button { editingCircuit = circuit } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button {
                                        store.deleteCircuit(circuit)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        DisclaimerBanner()
                            .padding(.top, 4)
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Circuit Board", displayMode: .inline)
            .navigationBarItems(trailing:
                NavigationLink(destination: CableAdvisorView()) {
                    Image(systemName: "ruler.fill").foregroundColor(Theme.primary)
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAddCircuit) { AddCircuitView() }
        .sheet(isPresented: $showAddDevice) { AddDeviceView() }
        .sheet(item: $editingCircuit) { c in AddCircuitView(editing: c) }
        .sheet(isPresented: $showBalance) { AutoBalanceSheet() }
    }

    private var summaryHeader: some View {
        let totals = store.houseTotals()
        return Card(glow: totals.overloadCount > 0 ? Theme.overload.opacity(0.4) : Theme.sparkGlow) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(store.supply.phase.rawValue) · \(store.supply.voltage) V")
                            .font(Theme.caption(12)).foregroundColor(Theme.textSecond)
                        Text("Main \(store.supply.mainBreaker) A")
                            .font(Theme.heading(17)).foregroundColor(Theme.text)
                    }
                    Spacer()
                    StatusBadge(status: totals.overloadCount > 0 ? .overload :
                                    (totals.headroom < 15 ? .tight : .ok))
                }
                Divider().background(Theme.border)
                HStack {
                    MonoStat(value: Fmt.watts(totals.totalWatts), label: "House load", color: Theme.primary)
                    Spacer()
                    MonoStat(value: Fmt.amps(totals.totalCurrent), label: "Current", color: Theme.circuit)
                    Spacer()
                    MonoStat(value: "\(store.circuits.count)", label: "Circuits", color: Theme.text)
                }
                if totals.overloadCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                        Text("\(totals.overloadCount) circuit(s) overloaded — run Auto-Balance.")
                            .font(Theme.caption(12))
                    }
                    .foregroundColor(Theme.overload)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            PillButton(title: "Add Circuit", systemImage: "plus.square.fill") { showAddCircuit = true }
            PillButton(title: "Add Device", systemImage: "powerplug.fill", tint: Theme.circuit) {
                showAddDevice = true
            }
            PillButton(title: "Balance", systemImage: "arrow.left.arrow.right", tint: Theme.copperHi) {
                showBalance = true
            }
        }
    }
}

// MARK: - Circuit row

struct CircuitRow: View {
    let load: CircuitLoad

    var body: some View {
        Card(glow: load.status == .overload ? Theme.overload.opacity(0.35) : nil) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: load.circuit.colorHex).opacity(0.18))
                            .frame(width: 42, height: 42)
                        Image(systemName: load.circuit.kind.icon)
                            .foregroundColor(Color(hex: load.circuit.colorHex))
                            .font(.system(size: 18, weight: .semibold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(load.circuit.name).font(Theme.heading(16)).foregroundColor(Theme.text)
                        Text("\(load.circuit.kind.rawValue) · \(load.deviceCount) device(s) · \(load.circuit.leg.rawValue)")
                            .font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                    }
                    Spacer()
                    StatusBadge(status: load.status)
                }

                LoadGauge(usage: load.usage, status: load.status)

                HStack {
                    MonoStat(value: Fmt.watts(load.totalWatts), label: "Load")
                    Spacer()
                    MonoStat(value: Fmt.amps(load.current), label: "Current", color: load.status.color)
                    Spacer()
                    MonoStat(value: "\(load.circuit.breakerRating) A", label: "Breaker")
                    Spacer()
                    MonoStat(value: Fmt.percent(max(0, load.reserve)), label: "Reserve",
                             color: load.reserve < 0 ? Theme.overload : Theme.textSecond)
                }
            }
        }
    }
}
