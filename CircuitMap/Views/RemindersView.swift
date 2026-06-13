//
//  RemindersView.swift
//  CircuitMap
//
//  Feature 14 — Reminders. Schedule "check balance" / "buy cable" reminders
//  via UNUserNotificationCenter.
//

import SwiftUI

struct RemindersView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var notifications: NotificationManager
    @State private var showAdd = false

    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Space.m) {
                    if !notifications.authorized { authCard }

                    if store.reminders.isEmpty {
                        Card {
                            EmptyState(icon: "bell.slash",
                                       title: "No reminders",
                                       message: "Schedule a reminder to re-check balance or buy cable.")
                        }
                    } else {
                        ForEach(store.reminders.sorted { $0.date < $1.date }) { reminder in
                            reminderRow(reminder)
                        }
                    }
                    PrimaryButton(title: "Add Reminder", systemImage: "plus.circle.fill") {
                        if !notifications.authorized {
                            notifications.requestAuthorization { _ in showAdd = true }
                        } else {
                            showAdd = true
                        }
                    }
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle("Reminders", displayMode: .inline)
        .sheet(isPresented: $showAdd) { AddReminderSheet() }
        .onAppear { notifications.refreshStatus() }
    }

    private var authCard: some View {
        Card(glow: Theme.tight.opacity(0.3)) {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill").foregroundColor(Theme.tight)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications off").font(Theme.heading(14)).foregroundColor(Theme.text)
                    Text("Enable to receive scheduled reminders.").font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                }
                Spacer()
                Button("Enable") { notifications.requestAuthorization() }
                    .font(Theme.caption(13)).foregroundColor(Theme.primary)
            }
        }
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: reminder.kind.icon)
                    .foregroundColor(Theme.primary).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title).font(Theme.body(15)).foregroundColor(Theme.text)
                    Text(Fmt.dateTimeStr(reminder.date)).font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { reminder.enabled },
                    set: { var r = reminder; r.enabled = $0; store.updateReminder(r) }))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Theme.primary))
                Button(action: { store.deleteReminder(reminder) }) {
                    Image(systemName: "trash").foregroundColor(Theme.textMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct AddReminderSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var kind: ReminderKind = .checkBalance
    @State private var title = ""
    @State private var date = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                FieldLabel(text: "Type")
                                HStack(spacing: 8) {
                                    ForEach(ReminderKind.allCases) { k in
                                        Chip(title: k.rawValue, systemImage: k.icon, selected: kind == k) {
                                            kind = k
                                            if title.isEmpty { title = k.rawValue }
                                        }
                                    }
                                }
                                FieldLabel(text: "Note")
                                ThemedTextField(placeholder: "e.g. Re-check after adding oven", text: $title)
                            }
                        }
                        Card {
                            DatePicker("When", selection: $date, in: Date()...,
                                       displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .accentColor(Theme.primary)
                                .foregroundColor(Theme.text)
                        }
                        PrimaryButton(title: "Schedule", systemImage: "bell.fill") {
                            let t = title.trimmingCharacters(in: .whitespaces)
                            store.addReminder(Reminder(title: t.isEmpty ? kind.rawValue : t, kind: kind, date: date))
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Add Reminder", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(Theme.textSecond))
            .onAppear { if title.isEmpty { title = kind.rawValue } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
