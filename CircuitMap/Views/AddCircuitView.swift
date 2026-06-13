//
//  AddCircuitView.swift
//  CircuitMap
//
//  Feature 02 — Add / edit a circuit (breaker group): name, kind, breaker
//  rating, cable type, cross-section, length, phase leg.
//

import SwiftUI

struct AddCircuitView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode

    let editing: Circuit?

    @State private var name: String
    @State private var kind: CircuitKind
    @State private var rating: Int
    @State private var cableType: CableType
    @State private var cableArea: Double
    @State private var length: Int
    @State private var leg: PhaseLeg
    @State private var colorHex: UInt

    private let colors: [UInt] = [0xFACC15, 0xFDE047, 0xD97706, 0xFBBF24, 0x38BDF8, 0x22C55E]

    init(editing: Circuit? = nil) {
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _kind = State(initialValue: editing?.kind ?? .socket)
        _rating = State(initialValue: editing?.breakerRating ?? CircuitKind.socket.defaultRating)
        _cableType = State(initialValue: editing?.cableType ?? .copperPVC)
        _cableArea = State(initialValue: editing?.cableArea ?? 2.5)
        _length = State(initialValue: Int(editing?.cableLength ?? 12))
        _leg = State(initialValue: editing?.leg ?? .l1)
        _colorHex = State(initialValue: editing?.colorHex ?? 0xFACC15)
    }

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                FieldLabel(text: "Circuit name")
                                ThemedTextField(placeholder: "e.g. Kitchen sockets", text: $name)

                                FieldLabel(text: "Type")
                                HStack(spacing: 8) {
                                    ForEach(CircuitKind.allCases) { k in
                                        Chip(title: k.rawValue, systemImage: k.icon, selected: kind == k) {
                                            kind = k
                                            rating = k.defaultRating
                                            cableArea = ElectricalReference.recommendedArea(forBreaker: rating)
                                        }
                                    }
                                }
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                FieldLabel(text: "Breaker rating")
                                ratingPicker
                                Divider().background(Theme.border)
                                ValueStepper(label: "Cable length", value: $length, range: 1...120, unit: " m")
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                FieldLabel(text: "Cable type")
                                HStack(spacing: 8) {
                                    ForEach(CableType.allCases) { c in
                                        Chip(title: c.rawValue, selected: cableType == c) { cableType = c }
                                    }
                                }
                                FieldLabel(text: "Cross-section")
                                areaPicker
                                hintRow
                            }
                        }

                        if store.supply.phase == .three {
                            Card {
                                VStack(alignment: .leading, spacing: 12) {
                                    FieldLabel(text: "Phase leg")
                                    HStack(spacing: 8) {
                                        ForEach(PhaseLeg.allCases) { l in
                                            Chip(title: l.rawValue, selected: leg == l, accent: Theme.circuit) { leg = l }
                                        }
                                    }
                                }
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                FieldLabel(text: "Color tag")
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { c in
                                        Circle()
                                            .fill(Color(hex: c))
                                            .frame(width: 30, height: 30)
                                            .overlay(Circle().stroke(Theme.text, lineWidth: colorHex == c ? 2 : 0))
                                            .onTapGesture { colorHex = c }
                                    }
                                    Spacer()
                                }
                            }
                        }

                        PrimaryButton(title: editing == nil ? "Add Circuit" : "Save Changes",
                                      systemImage: "checkmark.circle.fill", enabled: isValid) {
                            save()
                        }
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle(editing == nil ? "Add Circuit" : "Edit Circuit", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }.foregroundColor(Theme.textSecond))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var ratingPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ElectricalReference.standardBreakers, id: \.self) { r in
                    Chip(title: "\(r) A", selected: rating == r) {
                        rating = r
                        cableArea = ElectricalReference.recommendedArea(forBreaker: r)
                    }
                }
            }
        }
    }

    private var areaPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ElectricalReference.standardAreas, id: \.self) { a in
                    Chip(title: ElectricalReference.areaLabel(a), selected: cableArea == a, accent: Theme.circuit) {
                        cableArea = a
                    }
                }
            }
        }
    }

    private var hintRow: some View {
        let ampacity = ElectricalReference.ampacity(forArea: cableArea)
        let ok = ampacity >= Double(rating)
        return HStack(spacing: 6) {
            Image(systemName: ok ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(ok ? Theme.ok : Theme.tight)
            Text(ok
                 ? "\(ElectricalReference.areaLabel(cableArea)) handles ~\(Int(ampacity)) A — fits \(rating) A breaker."
                 : "\(ElectricalReference.areaLabel(cableArea)) (~\(Int(ampacity)) A) may be undersized for \(rating) A.")
                .font(Theme.caption(11)).foregroundColor(Theme.textSecond)
        }
    }

    private func save() {
        var c = editing ?? Circuit(name: name, kind: kind, breakerRating: rating)
        c.name = name.trimmingCharacters(in: .whitespaces)
        c.kind = kind
        c.breakerRating = rating
        c.cableType = cableType
        c.cableArea = cableArea
        c.cableLength = Double(length)
        c.leg = leg
        c.colorHex = colorHex
        if editing == nil { store.addCircuit(c) } else { store.updateCircuit(c) }
        dismiss()
    }

    private func dismiss() { presentationMode.wrappedValue.dismiss() }
}
