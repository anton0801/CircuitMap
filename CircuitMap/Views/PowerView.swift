//
//  PowerView.swift
//  CircuitMap
//
//  Tab 3 — Power. Hosts Main Balance (08) and Cost Estimate (09) behind a
//  segmented switch.
//

import SwiftUI

struct PowerView: View {
    @State private var segment = 0

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                VStack(spacing: 0) {
                    Picker("", selection: $segment) {
                        Text("Main Balance").tag(0)
                        Text("Cost Estimate").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(Theme.Space.m)

                    ScrollView(showsIndicators: false) {
                        Group {
                            if segment == 0 { MainBalanceView() }
                            else { CostEstimateView() }
                        }
                        .padding(.horizontal, Theme.Space.m)
                        .padding(.bottom, Theme.Space.m)
                    }
                }
            }
            .navigationBarTitle("Power", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct ScreenView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false

    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                ScreenRig(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: .screenWake)) { _ in reload() }
    }

    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: RailKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: RailKey.loadURL) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: RailKey.pushURL) }
    }

    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: RailKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: RailKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}
