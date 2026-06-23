//
//  ContentView.swift
//  CircuitMap
//
//  Root state machine: Splash → (first launch) Onboarding → Main App.
//

import SwiftUI

enum AppPhase { case onboarding, main }

struct RootView: View {
    
    @AppStorage("appearance") private var appearanceRaw = AppAppearance.dark.rawValue

    private var appearance: AppAppearance { AppAppearance(rawValue: appearanceRaw) ?? .dark }
    
    @EnvironmentObject var store: AppStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var phase: AppPhase = .main
    @Environment(\.scenePhase) private var scenePhase
    
    init() { Self.configureGlobalAppearance() }

    var body: some View {
        ZStack {
            switch phase {
            case .onboarding:
                OnboardingView {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.5)) { phase = .main }
                }
                .transition(.opacity)

            case .main:
                RootTabView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                phase = .onboarding
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { store.flush() }
        }
        .preferredColorScheme(appearance.colorScheme)
    }
    
    private static func configureGlobalAppearance() {
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = UIColor(hex: 0x100E08, alpha: 0.85)
        nav.titleTextAttributes = [.foregroundColor: UIColor(hex: 0xFEF9E7)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(hex: 0xFEF9E7)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(hex: 0xFACC15)
    }
    
}
