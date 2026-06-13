//
//  HistoryView.swift
//  CircuitMap
//
//  Feature 13 — History. Chronological added / balanced / checked events.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Space.m) {
                    if store.history.isEmpty {
                        Card {
                            EmptyState(icon: "clock.arrow.circlepath",
                                       title: "No history yet",
                                       message: "Adding circuits, devices and balancing will appear here.")
                        }
                    } else {
                        Card {
                            VStack(spacing: 0) {
                                ForEach(store.history) { event in
                                    HStack(spacing: 12) {
                                        Image(systemName: event.kind.icon)
                                            .foregroundColor(color(for: event.kind))
                                            .frame(width: 26)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.detail).font(Theme.body(14)).foregroundColor(Theme.text)
                                            Text(Fmt.dateTimeStr(event.date)).font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    if event.id != store.history.last?.id { Divider().background(Theme.border) }
                                }
                            }
                        }
                        SecondaryButton(title: "Clear History", systemImage: "trash") {
                            store.clearHistory()
                        }
                    }
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle("History", displayMode: .inline)
    }

    private func color(for kind: HistoryKind) -> Color {
        switch kind {
        case .added: return Theme.ok
        case .balanced: return Theme.copperHi
        case .checked: return Theme.circuit
        case .edited: return Theme.primary
        case .removed: return Theme.overload
        }
    }
}
