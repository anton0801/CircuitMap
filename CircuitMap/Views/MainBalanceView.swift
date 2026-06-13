//
//  MainBalanceView.swift
//  CircuitMap
//
//  Feature 08 — Main Balance. Whole-house load vs incoming main, plus
//  per-phase balance for 3-phase supplies.
//

import SwiftUI

struct MainBalanceView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let totals = store.houseTotals()
        VStack(spacing: Theme.Space.m) {
            capacityCard(totals)
            if store.supply.phase == .three { phaseCard }
            contributionCard
            DisclaimerBanner()
        }
    }

    private func capacityCard(_ totals: HouseTotals) -> some View {
        let usage = totals.capacityWatts > 0 ? totals.totalWatts / totals.capacityWatts : 0
        let status: LoadStatus = totals.isOverCapacity ? .overload : (totals.headroom < 15 ? .tight : .ok)
        return Card(glow: status == .overload ? Theme.overload.opacity(0.4) : Theme.sparkGlow) {
            VStack(spacing: 14) {
                RingGauge(fraction: usage, color: status.color,
                          label: Fmt.percent(usage * 100), sublabel: "of main")
                    .frame(width: 150, height: 150)
                StatusBadge(status: status)
                HStack {
                    MonoStat(value: Fmt.watts(totals.totalWatts), label: "House load", color: Theme.primary)
                    Spacer()
                    MonoStat(value: Fmt.amps(totals.totalCurrent), label: "Current", color: Theme.circuit)
                    Spacer()
                    MonoStat(value: "\(store.supply.mainBreaker) A", label: "Main")
                }
                Text(totals.isOverCapacity
                     ? "House load exceeds the main capacity — stagger high-power use or upsize the main."
                     : "Headroom: \(Fmt.percent(max(0, totals.headroom))) under the \(store.supply.mainBreaker) A main.")
                    .font(Theme.caption(11))
                    .foregroundColor(totals.isOverCapacity ? Theme.overload : Theme.textSecond)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var phaseCard: some View {
        let legs = store.phaseBalance()
        let maxWatts = max(legs.map { $0.watts }.max() ?? 1, 1)
        let imbalance = LoadEngine.imbalancePercent(legs)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Phase balance", systemImage: "chart.bar.fill", accent: Theme.circuit)
                    Text(Fmt.percent(imbalance) + " off")
                        .font(Theme.numeric(12))
                        .foregroundColor(imbalance > 20 ? Theme.tight : Theme.ok)
                }
                ForEach(legs) { leg in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(leg.leg.rawValue).font(Theme.numeric(13)).foregroundColor(Theme.text)
                            Spacer()
                            Text(Fmt.watts(leg.watts)).font(Theme.numeric(13)).foregroundColor(Theme.circuit)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.bgDeep)
                                Capsule().fill(Theme.circuit)
                                    .frame(width: max(6, CGFloat(leg.watts / maxWatts) * geo.size.width))
                            }
                        }
                        .frame(height: 8)
                    }
                }
                if imbalance > 20 {
                    Text("Legs are uneven — move circuits between L1/L2/L3 to balance.")
                        .font(Theme.caption(11)).foregroundColor(Theme.tight)
                }
            }
        }
    }

    private var contributionCard: some View {
        let loads = store.loads().sorted { $0.totalWatts > $1.totalWatts }
        let maxW = max(loads.map { $0.totalWatts }.max() ?? 1, 1)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Circuit contribution", systemImage: "list.bullet")
                if loads.isEmpty {
                    Text("No circuits yet.").font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                }
                ForEach(loads) { load in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(Color(hex: load.circuit.colorHex)).frame(width: 8, height: 8)
                            Text(load.circuit.name).font(Theme.body(13)).foregroundColor(Theme.text)
                            Spacer()
                            Text(Fmt.watts(load.totalWatts)).font(Theme.numeric(12)).foregroundColor(Theme.textSecond)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.bgDeep)
                                Capsule().fill(Color(hex: load.circuit.colorHex))
                                    .frame(width: max(4, CGFloat(load.totalWatts / maxW) * geo.size.width))
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }
}
