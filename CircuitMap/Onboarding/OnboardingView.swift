//
//  OnboardingView.swift
//  CircuitMap
//
//  Four interactive pages. Each has a distinct gesture:
//   O1 tap (spark burst), O2 drag (dial), O3 scroll + multi-select,
//   O4 tap-to-flip card. Writes choices into AppStore on completion.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    let onComplete: () -> Void

    @State private var page = 0

    // choices
    @State private var phase: SupplyPhase = .single
    @State private var voltage: Int = 230
    @State private var mainBreaker: Int = 40
    @State private var selectedRooms: Set<String> = ["Kitchen", "Living room", "Bathroom"]
    @State private var standard: RegionStandard = .iec

    private let roomOptions: [(String, String)] = [
        ("Kitchen", "fork.knife"), ("Living room", "sofa.fill"),
        ("Bathroom", "shower.fill"), ("Bedroom", "bed.double.fill"),
        ("Hallway", "door.left.hand.closed"), ("Office", "desktopcomputer"),
        ("Garage", "car.fill"), ("Utility", "washer.fill")
    ]

    var body: some View {
        ZStack {
            CircuitBackground(animated: true)

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(Theme.caption(14))
                        .foregroundColor(Theme.textSecond)
                        .padding(.horizontal, Theme.Space.m)
                        .padding(.top, Theme.Space.m)
                }

                TabView(selection: $page) {
                    SupplyPage(phase: $phase, voltage: $voltage).tag(0)
                    MainBreakerPage(mainBreaker: $mainBreaker).tag(1)
                    RoomsPage(options: roomOptions, selected: $selectedRooms).tag(2)
                    StandardPage(standard: $standard, voltage: $voltage).tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // dots
                HStack(spacing: 8) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == page ? Theme.primary : Theme.border)
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.vertical, 14)

                // primary action
                PrimaryButton(title: primaryTitle, systemImage: page == 3 ? "map.fill" : "arrow.right") {
                    advance()
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.bottom, Theme.Space.l)
            }
        }
    }

    private var primaryTitle: String {
        switch page {
        case 0: return "Set Supply"
        case 1: return "Set Main"
        case 2: return "Add Rooms"
        default: return "Build Map"
        }
    }

    private func advance() {
        if page < 3 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        var supply = store.supply
        supply.phase = phase
        supply.voltage = voltage
        supply.mainBreaker = mainBreaker
        supply.standard = standard
        store.updateSupply(supply)

        // add chosen rooms not already present
        let palette: [UInt] = [0xFACC15, 0x38BDF8, 0x22C55E, 0xD97706, 0xFDE047, 0xFBBF24]
        for (idx, name) in selectedRooms.sorted().enumerated() {
            if !store.rooms.contains(where: { $0.name == name }) {
                let icon = roomOptions.first(where: { $0.0 == name })?.1 ?? "square.fill"
                store.addRoom(Room(name: name, colorHex: palette[idx % palette.count], icon: icon))
            }
        }
        onComplete()
    }
}

// MARK: - O1 Supply (tap → spark burst)

private struct SupplyPage: View {
    @Binding var phase: SupplyPhase
    @Binding var voltage: Int
    @State private var sparks: [SparkParticle] = []
    @State private var iconScale: CGFloat = 1

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            OnboardHeader(step: "01", title: "Supply Type",
                          subtitle: "Tap the source to switch phase. This sets the load formulas.")

            ZStack {
                ForEach(sparks) { spark in
                    Circle()
                        .fill(Theme.primaryHi)
                        .frame(width: spark.size, height: spark.size)
                        .offset(x: spark.dx, y: spark.dy)
                        .opacity(spark.opacity)
                }
                Button(action: tap) {
                    ZStack {
                        Circle()
                            .fill(Theme.card)
                            .frame(width: 150, height: 150)
                            .overlay(Circle().stroke(Theme.primary.opacity(0.5), lineWidth: 2))
                        VStack(spacing: 6) {
                            Image(systemName: phase.icon)
                                .font(.system(size: 46, weight: .bold))
                                .foregroundColor(Theme.primary)
                                .shadow(color: Theme.sparkGlow, radius: 10)
                            Text(phase.rawValue)
                                .font(Theme.heading(15))
                                .foregroundColor(Theme.text)
                        }
                    }
                    .scaleEffect(iconScale)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(height: 200)

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel(text: "Voltage")
                    HStack(spacing: 10) {
                        ForEach([220, 230], id: \.self) { v in
                            Chip(title: "\(v) V", selected: voltage == v) { voltage = v }
                        }
                        Spacer()
                    }
                    Text(phase == .single
                         ? "Single-phase: I = ΣW ÷ \(voltage) V per circuit."
                         : "Three-phase: balance circuits across L1 · L2 · L3.")
                        .font(Theme.caption(12))
                        .foregroundColor(Theme.textSecond)
                }
            }
            Spacer()
        }
        .padding(Theme.Space.l)
        .onDisappear { sparks = [] }
    }

    private func tap() {
        let g = UIImpactFeedbackGenerator(style: .medium); g.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            phase = phase == .single ? .three : .single
            iconScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring()) { iconScale = 1 }
        }
        burst()
    }

    private func burst() {
        var new: [SparkParticle] = []
        for i in 0..<14 {
            let angle = Double(i) / 14 * 2 * .pi
            new.append(SparkParticle(angle: angle))
        }
        sparks = new
        for idx in sparks.indices {
            let angle = sparks[idx].angle
            withAnimation(.easeOut(duration: 0.6)) {
                sparks[idx].dx = CGFloat(cos(angle)) * 110
                sparks[idx].dy = CGFloat(sin(angle)) * 110
                sparks[idx].opacity = 0
                sparks[idx].size = 3
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { sparks = [] }
    }
}

private struct SparkParticle: Identifiable {
    let id = UUID()
    let angle: Double
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var opacity: Double = 1
    var size: CGFloat = 8
}

// MARK: - O2 Main breaker (drag dial)

private struct MainBreakerPage: View {
    @Binding var mainBreaker: Int
    private let ratings = ElectricalReference.standardBreakers
    @State private var dragAngle: Double = 0

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            OnboardHeader(step: "02", title: "Main Breaker",
                          subtitle: "Drag around the dial to set your incoming main rating (A).")

            ZStack {
                Circle().stroke(Theme.bgDeep, lineWidth: 16).frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: CGFloat(fraction))
                    .stroke(Theme.primaryGradient,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .shadow(color: Theme.sparkGlow, radius: 8)

                // needle knob
                Circle()
                    .fill(Theme.primaryHi)
                    .frame(width: 22, height: 22)
                    .shadow(color: Theme.sparkGlow, radius: 6)
                    .offset(y: -100)
                    .rotationEffect(.degrees(fraction * 360))

                VStack(spacing: 2) {
                    Text("\(mainBreaker)")
                        .font(Theme.numeric(46, weight: .heavy))
                        .foregroundColor(Theme.mono)
                    Text("AMPERE").font(Theme.caption(11)).tracking(2).foregroundColor(Theme.textMuted)
                }
            }
            .frame(width: 220, height: 220)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in updateFromDrag(value.location) }
            )

            Card {
                HStack {
                    Image(systemName: "info.circle.fill").foregroundColor(Theme.circuit)
                    Text("Total household load must stay under \(mainBreaker) A × \(220) V.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecond)
                }
            }
            Spacer()
        }
        .padding(Theme.Space.l)
    }

    private var index: Int { ratings.firstIndex(of: mainBreaker) ?? 6 }
    private var fraction: Double {
        guard let maxR = ratings.last, let minR = ratings.first, maxR > minR else { return 0 }
        return Double(mainBreaker - minR) / Double(maxR - minR)
    }

    private func updateFromDrag(_ location: CGPoint) {
        // center of the 220x220 box
        let center = CGPoint(x: 110, y: 110)
        let dx = location.x - center.x
        let dy = location.y - center.y
        var angle = atan2(dy, dx) + .pi / 2 // 0 at top
        if angle < 0 { angle += 2 * .pi }
        let frac = angle / (2 * .pi)
        let idx = Int((frac * Double(ratings.count - 1)).rounded())
        let clamped = min(max(idx, 0), ratings.count - 1)
        if ratings[clamped] != mainBreaker {
            let g = UISelectionFeedbackGenerator(); g.selectionChanged()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                mainBreaker = ratings[clamped]
            }
        }
    }
}

// MARK: - O3 Rooms (scroll + multi-select stagger-in)

private struct RoomsPage: View {
    let options: [(String, String)]
    @Binding var selected: Set<String>
    @State private var appeared = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            OnboardHeader(step: "03", title: "Rooms",
                          subtitle: "Pick the rooms to plan. Each becomes a zone for circuits.")

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                        roomCard(opt.0, opt.1, idx: idx)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.top, 4)
            }

            Text("\(selected.count) room(s) selected")
                .font(Theme.caption(12)).foregroundColor(Theme.textSecond)
        }
        .padding(Theme.Space.l)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .onDisappear { appeared = false }
    }

    private func roomCard(_ name: String, _ icon: String, idx: Int) -> some View {
        let isOn = selected.contains(name)
        return Button(action: {
            let g = UISelectionFeedbackGenerator(); g.selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isOn { selected.remove(name) } else { selected.insert(name) }
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(isOn ? Theme.primaryText : Theme.primary)
                Text(name).font(Theme.body(14)).foregroundColor(isOn ? Theme.primaryText : Theme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .fill(isOn ? Theme.primary : Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
                        .stroke(isOn ? Theme.primary : Theme.border, lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(idx) * 0.05), value: appeared)
    }
}

// MARK: - O4 Standard (tap to flip card)

private struct StandardPage: View {
    @Binding var standard: RegionStandard
    @Binding var voltage: Int
    @State private var flipped = false

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            OnboardHeader(step: "04", title: "Standard",
                          subtitle: "Choose a regional default. Tap the card to see cable hints.")

            // flip card
            ZStack {
                if !flipped { frontCard } else { backCard.rotation3DEffect(.degrees(180), axis: (0,1,0)) }
            }
            .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: flipped)
            .onTapGesture {
                let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred()
                flipped.toggle()
            }

            VStack(spacing: 10) {
                ForEach(RegionStandard.allCases) { std in
                    Chip(title: std.rawValue, systemImage: "globe", selected: standard == std) {
                        withAnimation(.spring()) {
                            standard = std
                            voltage = std.defaultVoltage == 120 ? 230 : std.defaultVoltage
                            flipped = false
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(Theme.Space.l)
        .onDisappear { flipped = false }
    }

    private var frontCard: some View {
        Card(glow: Theme.sparkGlow) {
            VStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40)).foregroundColor(Theme.primary)
                Text(standard.rawValue).font(Theme.heading(18)).foregroundColor(Theme.text)
                Text(standard.note).font(Theme.caption(12))
                    .foregroundColor(Theme.textSecond).multilineTextAlignment(.center)
                Text("Tap to flip ›").font(Theme.caption(11)).foregroundColor(Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
        }
    }

    private var backCard: some View {
        Card(glow: Theme.circuitGlow) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Cable hint", systemImage: "bolt.horizontal.circle.fill", accent: Theme.circuit)
                hintRow("Lighting", "1.5 mm² · 10 A")
                hintRow("Sockets", "2.5 mm² · 16 A")
                hintRow("Power", "4–6 mm² · 25–32 A")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 150)
        }
    }

    private func hintRow(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(Theme.body(13)).foregroundColor(Theme.text)
            Spacer()
            Text(b).font(Theme.numeric(13)).foregroundColor(Theme.circuit)
        }
    }
}

// MARK: - Shared header

private struct OnboardHeader: View {
    let step: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text("STEP \(step)")
                .font(Theme.caption(11)).tracking(2).foregroundColor(Theme.primary)
            Text(title)
                .font(Theme.title(28)).foregroundColor(Theme.text)
            Text(subtitle)
                .font(Theme.body(14)).foregroundColor(Theme.textSecond)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }
}
