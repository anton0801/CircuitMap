//
//  RoomView.swift
//  CircuitMap
//
//  Feature 06 — Room View. All points by room (sockets/lights/outputs) and
//  their circuit links. Drills into a room detail + socket plan.
//

import SwiftUI

struct RoomView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddRoom = false

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        if store.rooms.isEmpty {
                            Card {
                                EmptyState(icon: "square.split.2x2",
                                           title: "No rooms",
                                           message: "Add a room to start placing sockets, lights and outputs.")
                            }
                        } else {
                            ForEach(store.rooms) { room in
                                NavigationLink(destination: RoomDetailView(roomID: room.id)) {
                                    RoomCard(room: room)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button { store.deleteRoom(room) } label: {
                                        Label("Delete room", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        PrimaryButton(title: "Add Room", systemImage: "plus.circle.fill") { showAddRoom = true }
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Rooms", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAddRoom) { AddRoomSheet() }
    }
}

private struct RoomCard: View {
    @EnvironmentObject var store: AppStore
    let room: Room

    var body: some View {
        let devices = store.devices(in: room.id)
        let points = store.points(in: room.id)
        let totalWatts = devices.reduce(0) { $0 + $1.load }
        return Card {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: room.colorHex).opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: room.icon).font(.system(size: 22))
                        .foregroundColor(Color(hex: room.colorHex))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(room.name).font(Theme.heading(17)).foregroundColor(Theme.text)
                    Text("\(points.reduce(0) { $0 + $1.count }) points · \(devices.count) devices")
                        .font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.watts(totalWatts)).font(Theme.numeric(15)).foregroundColor(Theme.primary)
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Theme.textMuted)
                }
            }
        }
    }
}

// MARK: - Room detail

struct RoomDetailView: View {
    @EnvironmentObject var store: AppStore
    let roomID: UUID

    @State private var showAddDevice = false
    @State private var showAddPoint = false

    private var room: Room? { store.rooms.first(where: { $0.id == roomID }) }

    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Space.m) {
                    NavigationLink(destination: SocketPlanView(roomID: roomID)) {
                        socketPlanLink
                    }
                    .buttonStyle(PlainButtonStyle())

                    pointsCard
                    devicesCard

                    HStack(spacing: 10) {
                        PillButton(title: "Add Point", systemImage: "mappin.circle.fill") { showAddPoint = true }
                        PillButton(title: "Add Device", systemImage: "powerplug.fill", tint: Theme.circuit) { showAddDevice = true }
                    }
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle(room?.name ?? "Room", displayMode: .inline)
        .sheet(isPresented: $showAddDevice) { AddDeviceView(presetRoomID: roomID) }
        .sheet(isPresented: $showAddPoint) { AddPointSheet(roomID: roomID) }
    }

    private var socketPlanLink: some View {
        Card {
            HStack {
                Image(systemName: "ruler.fill").foregroundColor(Theme.copperHi)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Socket plan").font(Theme.heading(15)).foregroundColor(Theme.text)
                    Text("Heights & ergonomics checklist").font(Theme.caption(11)).foregroundColor(Theme.textSecond)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Theme.textMuted)
            }
        }
    }

    private var pointsCard: some View {
        let points = store.points(in: roomID)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Points (\(points.reduce(0) { $0 + $1.count }))", systemImage: "mappin.and.ellipse")
                if points.isEmpty {
                    Text("No points placed yet.").font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(points) { p in
                        HStack {
                            Image(systemName: p.kind.icon).foregroundColor(Theme.primary).frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(p.count)× \(p.kind.rawValue)").font(Theme.body(14)).foregroundColor(Theme.text)
                                Text("\(store.circuitName(p.circuitID)) · \(p.height) cm")
                                    .font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            Button { store.deletePoint(p) } label: {
                                Image(systemName: "trash").foregroundColor(Theme.textMuted)
                            }
                        }
                        if p.id != points.last?.id { Divider().background(Theme.border) }
                    }
                }
            }
        }
    }

    private var devicesCard: some View {
        let devices = store.devices(in: roomID)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Devices (\(devices.count))", systemImage: "powerplug.fill")
                if devices.isEmpty {
                    Text("No devices in this room.").font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(devices) { d in
                        HStack {
                            Image(systemName: d.iconName).foregroundColor(Theme.circuit).frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(d.name).font(Theme.body(14)).foregroundColor(Theme.text)
                                Text(store.circuitName(d.circuitID)).font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            Text(Fmt.watts(d.load)).font(Theme.numeric(13)).foregroundColor(Theme.textSecond)
                        }
                        if d.id != devices.last?.id { Divider().background(Theme.border) }
                    }
                }
            }
        }
    }
}

// MARK: - Add room / add point sheets

struct AddRoomSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var name = ""
    @State private var icon = "square.split.bottomrightquarter.fill"
    @State private var colorHex: UInt = 0x38BDF8

    private let icons = ["fork.knife", "sofa.fill", "shower.fill", "bed.double.fill",
                         "door.left.hand.closed", "desktopcomputer", "car.fill", "washer.fill"]
    private let colors: [UInt] = [0xFACC15, 0x38BDF8, 0x22C55E, 0xD97706, 0xFDE047, 0xEF4444]

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                FieldLabel(text: "Room name")
                                ThemedTextField(placeholder: "e.g. Bedroom", text: $name)
                                FieldLabel(text: "Icon")
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                                    ForEach(icons, id: \.self) { ic in
                                        Image(systemName: ic)
                                            .font(.system(size: 20))
                                            .foregroundColor(icon == ic ? Theme.primaryText : Theme.primary)
                                            .frame(width: 52, height: 52)
                                            .background(RoundedRectangle(cornerRadius: 10).fill(icon == ic ? Theme.primary : Theme.bgDeep))
                                            .onTapGesture { icon = ic }
                                    }
                                }
                                FieldLabel(text: "Color")
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { c in
                                        Circle().fill(Color(hex: c)).frame(width: 30, height: 30)
                                            .overlay(Circle().stroke(Theme.text, lineWidth: colorHex == c ? 2 : 0))
                                            .onTapGesture { colorHex = c }
                                    }
                                }
                            }
                        }
                        PrimaryButton(title: "Add Room", systemImage: "checkmark.circle.fill",
                                      enabled: !name.trimmingCharacters(in: .whitespaces).isEmpty) {
                            store.addRoom(Room(name: name.trimmingCharacters(in: .whitespaces), colorHex: colorHex, icon: icon))
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Add Room", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(Theme.textSecond))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct AddPointSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    let roomID: UUID

    @State private var kind: PointKind = .socket
    @State private var count: Int = 1
    @State private var height: Int = 30
    @State private var circuitID: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Space.m) {
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                FieldLabel(text: "Point type")
                                HStack(spacing: 8) {
                                    ForEach(PointKind.allCases) { k in
                                        Chip(title: k.rawValue, systemImage: k.icon, selected: kind == k) {
                                            kind = k; height = k.standardHeight
                                        }
                                    }
                                }
                                ValueStepper(label: "Count", value: $count, range: 1...20)
                                ValueStepper(label: "Height", value: $height, range: 0...260, step: 5, unit: " cm")
                                Text("Standard height for \(kind.rawValue.lowercased()): \(kind.standardHeight) cm")
                                    .font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                            }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                FieldLabel(text: "Circuit")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(store.circuits) { c in
                                            Chip(title: c.name, selected: circuitID == c.id) { circuitID = c.id }
                                        }
                                    }
                                }
                            }
                        }
                        PrimaryButton(title: "Add Point", systemImage: "checkmark.circle.fill") {
                            store.addPoint(SocketPoint(roomID: roomID, kind: kind, count: count,
                                                       height: height, circuitID: circuitID))
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(Theme.Space.m)
                }
            }
            .navigationBarTitle("Add Point", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(Theme.textSecond))
            .onAppear { height = kind.standardHeight }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
