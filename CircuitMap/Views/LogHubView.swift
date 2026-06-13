//
//  LogHubView.swift
//  CircuitMap
//
//  Tab 4 — Log. Entry hub to Safety Notes, Photos, Reports, History and
//  Reminders.
//

import SwiftUI

struct LogHubView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        hubLink(destination: AnyView(SafetyNotesView()),
                                icon: "exclamationmark.shield.fill", tint: Theme.copperHi,
                                title: "Safety Notes",
                                detail: "\(store.notes.filter { $0.flagged && !$0.resolved }.count) flagged · \(store.notes.count) total")
                        hubLink(destination: AnyView(PhotoMarkerView()),
                                icon: "photo.stack.fill", tint: Theme.circuit,
                                title: "Photos & Markers",
                                detail: "\(store.photos.count) photo(s)")
                        hubLink(destination: AnyView(ReportsView()),
                                icon: "doc.text.fill", tint: Theme.primary,
                                title: "Reports",
                                detail: "Schematic, loads & materials · Export PDF")
                        hubLink(destination: AnyView(HistoryView()),
                                icon: "clock.arrow.circlepath", tint: Theme.ok,
                                title: "History",
                                detail: "\(store.history.count) event(s)")
                        hubLink(destination: AnyView(RemindersView()),
                                icon: "bell.badge.fill", tint: Theme.tight,
                                title: "Reminders",
                                detail: "\(store.reminders.filter { $0.enabled }.count) active")
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Log", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func hubLink(destination: AnyView, icon: String, tint: Color,
                         title: String, detail: String) -> some View {
        NavigationLink(destination: destination) {
            Card {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(tint.opacity(0.18)).frame(width: 48, height: 48)
                        Image(systemName: icon).font(.system(size: 22)).foregroundColor(tint)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(Theme.heading(16)).foregroundColor(Theme.text)
                        Text(detail).font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(Theme.textMuted)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
