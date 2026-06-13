//
//  SocketPlanView.swift
//  CircuitMap
//
//  Feature 07 — Socket Plan. Per-room socket count and mounting-height
//  ergonomics checklist with standard-height hints.
//

import SwiftUI

struct SocketPlanView: View {
    @EnvironmentObject var store: AppStore
    let roomID: UUID

    private var room: Room? { store.rooms.first(where: { $0.id == roomID }) }

    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Space.m) {
                    summaryCard
                    heightGuideCard
                    checklistCard
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle("Socket Plan", displayMode: .inline)
    }

    private var points: [SocketPoint] { store.points(in: roomID) }

    private var summaryCard: some View {
        let sockets = points.filter { $0.kind == .socket }.reduce(0) { $0 + $1.count }
        let lights = points.filter { $0.kind == .light }.reduce(0) { $0 + $1.count }
        let outputs = points.filter { $0.kind == .output }.reduce(0) { $0 + $1.count }
        return Card(glow: Theme.sparkGlow) {
            HStack {
                MonoStat(value: "\(sockets)", label: "Sockets", color: Theme.primary)
                Spacer()
                MonoStat(value: "\(lights)", label: "Lights", color: Theme.copperHi)
                Spacer()
                MonoStat(value: "\(outputs)", label: "Outputs", color: Theme.circuit)
            }
        }
    }

    private var heightGuideCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Ergonomic heights", systemImage: "ruler.fill", accent: Theme.copperHi)
                guideRow("General socket", "30 cm")
                guideRow("Worktop socket", "110 cm")
                guideRow("Switch", "90–110 cm")
                guideRow("Wall light", "180–230 cm")
                guideRow("TV outlet", "120 cm")
            }
        }
    }

    private func guideRow(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(Theme.body(13)).foregroundColor(Theme.text)
            Spacer()
            Text(b).font(Theme.numeric(13)).foregroundColor(Theme.copperHi)
        }
    }

    private var checklistCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Checklist", systemImage: "checklist")
                if points.isEmpty {
                    Text("Add points in the room to build a checklist.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(points) { p in
                        Button(action: { toggle(p) }) {
                            HStack(spacing: 10) {
                                Image(systemName: p.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(p.done ? Theme.ok : Theme.textMuted)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(p.count)× \(p.kind.rawValue) @ \(p.height) cm")
                                        .font(Theme.body(14))
                                        .foregroundColor(Theme.text)
                                        .strikethrough(p.done, color: Theme.textMuted)
                                    heightHint(p)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        if p.id != points.last?.id { Divider().background(Theme.border) }
                    }
                }
            }
        }
    }

    private func heightHint(_ p: SocketPoint) -> some View {
        let diff = abs(p.height - p.kind.standardHeight)
        let ok = diff <= 20
        return Text(ok ? "Within ergonomic range" : "\(diff) cm from standard \(p.kind.standardHeight) cm")
            .font(Theme.caption(10))
            .foregroundColor(ok ? Theme.ok : Theme.tight)
    }

    private func toggle(_ p: SocketPoint) {
        var updated = p
        updated.done.toggle()
        let g = UISelectionFeedbackGenerator(); g.selectionChanged()
        store.updatePoint(updated)
    }
}
