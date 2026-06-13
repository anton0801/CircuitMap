//
//  CableAdvisorView.swift
//  CircuitMap
//
//  Feature 05 — Cable Advisor. Reference cross-section by current and run
//  length, with voltage-drop check against the kind limit.
//

import SwiftUI

struct CableAdvisorView: View {
    @EnvironmentObject var store: AppStore

    @State private var currentText: String = "16"
    @State private var lengthText: String = "20"
    @State private var cable: CableType = .copperPVC
    @State private var dropLimit: Double = 5.0

    private var current: Double { Double(currentText) ?? 0 }
    private var length: Double { Double(lengthText) ?? 0 }
    private var recommendedArea: Double { ElectricalReference.recommendedArea(forCurrent: current) }

    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Space.m) {
                    inputCard
                    resultCard
                    tableCard
                    DisclaimerBanner()
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle("Cable Advisor", displayMode: .inline)
    }

    private var inputCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                FieldLabel(text: "Load current (A)")
                ThemedTextField(placeholder: "e.g. 16", text: $currentText, keyboard: .numbersAndPunctuation)
                FieldLabel(text: "Run length (m)")
                ThemedTextField(placeholder: "e.g. 20", text: $lengthText, keyboard: .numbersAndPunctuation)
                FieldLabel(text: "Cable")
                HStack(spacing: 8) {
                    ForEach(CableType.allCases) { c in
                        Chip(title: c.rawValue, selected: cable == c) { cable = c }
                    }
                }
                FieldLabel(text: "Drop limit · \(Fmt.percent(dropLimit))")
                HStack(spacing: 8) {
                    Chip(title: "3% lighting", selected: dropLimit == 3) { dropLimit = 3 }
                    Chip(title: "5% power", selected: dropLimit == 5) { dropLimit = 5 }
                }
            }
        }
    }

    private var resultCard: some View {
        // pick smallest area that satisfies both ampacity and the drop limit
        let area = bestArea()
        let dropPct = ElectricalReference.voltageDropPercent(
            current: current, length: length, area: area, cable: cable, voltage: store.supply.voltage)
        let dropOK = dropPct <= dropLimit
        return Card(glow: dropOK ? Theme.sparkGlow : Theme.overload.opacity(0.3)) {
            VStack(spacing: 14) {
                Text("Suggested cross-section")
                    .font(Theme.caption(12)).foregroundColor(Theme.textSecond)
                Text(ElectricalReference.areaLabel(area))
                    .font(Theme.numeric(40, weight: .heavy))
                    .foregroundColor(Theme.primary)
                    .shadow(color: Theme.sparkGlow, radius: 8)
                HStack {
                    MonoStat(value: "\(Int(ElectricalReference.ampacity(forArea: area))) A", label: "Ampacity", color: Theme.circuit)
                    Spacer()
                    MonoStat(value: Fmt.percent(dropPct), label: "Volt drop",
                             color: dropOK ? Theme.ok : Theme.overload)
                    Spacer()
                    MonoStat(value: Fmt.num(ElectricalReference.voltageDrop(current: current, length: length, area: area, cable: cable), 1) + " V",
                             label: "ΔU")
                }
                HStack(spacing: 6) {
                    Image(systemName: dropOK ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(dropOK ? Theme.ok : Theme.tight)
                    Text(dropOK
                         ? "Within the \(Fmt.percent(dropLimit)) drop limit."
                         : "Over \(Fmt.percent(dropLimit)) — increase section or shorten the run.")
                        .font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var tableCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Copper ampacity reference", systemImage: "tablecells.fill")
                ForEach(ElectricalReference.ampacity, id: \.area) { row in
                    HStack {
                        Text(ElectricalReference.areaLabel(row.area))
                            .font(Theme.numeric(13))
                            .foregroundColor(abs(row.area - recommendedArea) < 0.01 ? Theme.primary : Theme.text)
                        Spacer()
                        Text("≈ \(Int(row.amps)) A")
                            .font(Theme.numeric(13)).foregroundColor(Theme.textSecond)
                    }
                    if row.area != ElectricalReference.ampacity.last?.area { Divider().background(Theme.border) }
                }
            }
        }
    }

    /// Smallest standard area meeting ampacity AND the voltage-drop limit.
    private func bestArea() -> Double {
        let byAmpacity = ElectricalReference.recommendedArea(forCurrent: current)
        for a in ElectricalReference.standardAreas where a >= byAmpacity {
            let drop = ElectricalReference.voltageDropPercent(
                current: current, length: length, area: a, cable: cable, voltage: store.supply.voltage)
            if drop <= dropLimit { return a }
        }
        return ElectricalReference.standardAreas.last ?? byAmpacity
    }
}
