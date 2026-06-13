//
//  AutoBalanceSheet.swift
//  CircuitMap
//
//  Runs the LoadEngine auto-balance, previews the before/after moves and
//  applies them on confirmation.
//

import SwiftUI

struct AutoBalanceSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var plan: BalancePlan?
    @State private var applied = false

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        beforeAfterCard
                        if let plan = plan {
                            if plan.hasChanges {
                                movesCard(plan)
                                if !applied {
                                    PrimaryButton(title: "Apply Balance", systemImage: "arrow.left.arrow.right.circle.fill") {
                                        store.applyBalance(plan)
                                        applied = true
                                        let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)
                                    }
                                } else {
                                    appliedBanner
                                }
                            } else {
                                Card {
                                    EmptyState(icon: "checkmark.seal.fill",
                                               title: "Already balanced",
                                               message: "No device moves reduce overloads with the current circuits.")
                                }
                            }
                        }
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Auto-Balance", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() }.foregroundColor(Theme.primary))
            .onAppear { if plan == nil { plan = store.balancePlan() } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var beforeAfterCard: some View {
        let before = store.overloadCount
        let after: Int = {
            guard let plan = plan else { return before }
            return LoadEngine.allLoads(circuits: store.circuits,
                                       devices: applied ? store.devices : plan.updatedDevices,
                                       voltage: store.supply.voltage)
                .filter { $0.status == .overload }.count
        }()
        return Card(glow: Theme.sparkGlow) {
            HStack {
                VStack(spacing: 4) {
                    Text("\(before)").font(Theme.numeric(34, weight: .heavy))
                        .foregroundColor(before > 0 ? Theme.overload : Theme.ok)
                    Text("OVERLOADS NOW").font(Theme.caption(9)).tracking(1).foregroundColor(Theme.textMuted)
                }
                Spacer()
                Image(systemName: "arrow.right").foregroundColor(Theme.primary)
                Spacer()
                VStack(spacing: 4) {
                    Text("\(after)").font(Theme.numeric(34, weight: .heavy))
                        .foregroundColor(after > 0 ? Theme.tight : Theme.ok)
                    Text("AFTER BALANCE").font(Theme.caption(9)).tracking(1).foregroundColor(Theme.textMuted)
                }
            }
        }
    }

    private func movesCard(_ plan: BalancePlan) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Proposed moves (\(plan.moves.count))", systemImage: "shuffle")
                ForEach(plan.moves) { move in
                    HStack(spacing: 8) {
                        Image(systemName: move.device.iconName).foregroundColor(Theme.circuit).frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(move.device.name).font(Theme.body(13)).foregroundColor(Theme.text)
                            HStack(spacing: 4) {
                                Text(move.fromCircuit).font(Theme.caption(10)).foregroundColor(Theme.overload)
                                Image(systemName: "arrow.right").font(.system(size: 8)).foregroundColor(Theme.textMuted)
                                Text(move.toCircuit).font(Theme.caption(10)).foregroundColor(Theme.ok)
                            }
                        }
                        Spacer()
                        Text(Fmt.watts(move.device.load)).font(Theme.numeric(12)).foregroundColor(Theme.textSecond)
                    }
                    if move.id != plan.moves.last?.id { Divider().background(Theme.border) }
                }
            }
        }
    }

    private var appliedBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.ok)
            Text("Balance applied and saved.").font(Theme.body(14)).foregroundColor(Theme.text)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.ok.opacity(0.12)))
    }

    private func dismiss() { presentationMode.wrappedValue.dismiss() }
}
