//
//  SafetyNotesView.swift
//  CircuitMap
//
//  Feature 10 — Safety Notes. Notes with flags (RCD on wet zones, grounding)
//  plus a suggested safety checklist.
//

import SwiftUI

struct SafetyNotesView: View {
    @EnvironmentObject var store: AppStore
    @State private var newText = ""
    @State private var newZone = "General"
    @State private var newFlagged = true

    private let suggestions = [
        "Fit a 30 mA RCD on bathroom and kitchen circuits.",
        "Verify main protective earthing and equipotential bonding.",
        "Use RCBOs for high-value or freezer circuits.",
        "Label every breaker clearly in the panel.",
        "Keep wet-zone sockets at safe distance from water."
    ]

    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Space.m) {
                    addCard
                    if !store.notes.isEmpty { notesCard }
                    suggestionsCard
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle("Safety Notes", displayMode: .inline)
    }

    private var addCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "New note", systemImage: "plus.circle.fill")
                ThemedTextField(placeholder: "e.g. RCD missing on bathroom", text: $newText)
                HStack {
                    ThemedTextField(placeholder: "Zone", text: $newZone)
                    Button(action: { newFlagged.toggle() }) {
                        Image(systemName: newFlagged ? "flag.fill" : "flag")
                            .foregroundColor(newFlagged ? Theme.overload : Theme.textMuted)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgDeep))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                PrimaryButton(title: "Add Note", systemImage: "checkmark",
                              enabled: !newText.trimmingCharacters(in: .whitespaces).isEmpty) {
                    store.addNote(SafetyNote(text: newText.trimmingCharacters(in: .whitespaces),
                                             flagged: newFlagged,
                                             zone: newZone.isEmpty ? "General" : newZone))
                    newText = ""; newZone = "General"; newFlagged = true
                    UIApplication.shared.endEditing()
                }
            }
        }
    }

    private var notesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Notes (\(store.notes.count))", systemImage: "list.bullet.clipboard.fill")
                ForEach(store.notes) { note in
                    HStack(alignment: .top, spacing: 10) {
                        Button(action: { toggleResolve(note) }) {
                            Image(systemName: note.resolved ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(note.resolved ? Theme.ok : Theme.textMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.text)
                                .font(Theme.body(14))
                                .foregroundColor(note.resolved ? Theme.textMuted : Theme.text)
                                .strikethrough(note.resolved)
                            HStack(spacing: 6) {
                                if note.flagged && !note.resolved {
                                    Image(systemName: "flag.fill").font(.system(size: 9)).foregroundColor(Theme.overload)
                                }
                                Text(note.zone).font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                            }
                        }
                        Spacer()
                        Button(action: { store.deleteNote(note) }) {
                            Image(systemName: "trash").foregroundColor(Theme.textMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    if note.id != store.notes.last?.id { Divider().background(Theme.border) }
                }
            }
        }
    }

    private var suggestionsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Suggested checks", systemImage: "lightbulb.fill", accent: Theme.copperHi)
                ForEach(suggestions, id: \.self) { s in
                    Button(action: { add(s) }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle").foregroundColor(Theme.primary)
                            Text(s).font(Theme.caption(12)).foregroundColor(Theme.textSecond)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func add(_ text: String) {
        guard !store.notes.contains(where: { $0.text == text }) else { return }
        let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred()
        store.addNote(SafetyNote(text: text, flagged: true, zone: "Suggested"))
    }

    private func toggleResolve(_ note: SafetyNote) {
        var updated = note
        updated.resolved.toggle()
        store.updateNote(updated)
    }
}
