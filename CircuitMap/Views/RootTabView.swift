//
//  RootTabView.swift
//  CircuitMap
//
//  Main app shell: five tabs behind a custom tab bar, plus a one-time
//  disclaimer sheet.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: AppTab = .board
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false
    @State private var showDisclaimer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            // active tab content
            Group {
                switch tab {
                case .board: CircuitBoardView()
                case .rooms: RoomView()
                case .power: PowerView()
                case .log: LogHubView()
                case .settings: SettingsView()
                }
            }
            .padding(.bottom, 64) // keep content above the tab bar

            CustomTabBar(selection: $tab)
        }
        .onAppear {
            if !disclaimerAccepted { showDisclaimer = true }
            NotificationManager.shared.refreshStatus()
        }
        .sheet(isPresented: $showDisclaimer) {
            DisclaimerSheet { disclaimerAccepted = true; showDisclaimer = false }
        }
    }
}

private struct DisclaimerSheet: View {
    let onAccept: () -> Void

    var body: some View {
        ZStack {
            CircuitBackground()
            VStack(spacing: Theme.Space.l) {
                Spacer()
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Theme.copperHi)
                    .shadow(color: Theme.sparkGlow, radius: 12)
                Text("Reference only")
                    .font(Theme.title(26)).foregroundColor(Theme.text)
                Text("Circuit Map helps you plan and sanity-check loads, breaker ratings and cable sizes. All values are conservative references for planning. They do not replace a licensed electrician's design, local code compliance, or on-site inspection.")
                    .font(Theme.body(15))
                    .foregroundColor(Theme.textSecond)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Space.l)
                Spacer()
                PrimaryButton(title: "I Understand", systemImage: "checkmark.circle.fill") {
                    onAccept()
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.bottom, Theme.Space.xl)
            }
        }
    }
}
