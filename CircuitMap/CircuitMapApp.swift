//
//  CircuitMapApp.swift
//  CircuitMap
//
//  App entry point. Injects AppStore + NotificationManager, applies the
//  selected appearance, configures global UIKit appearance and flushes
//  data on backgrounding.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@main
struct CircuitMapApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var notifications = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearance") private var appearanceRaw = AppAppearance.dark.rawValue

    private var appearance: AppAppearance { AppAppearance(rawValue: appearanceRaw) ?? .dark }

    init() { Self.configureGlobalAppearance() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notifications)
                .preferredColorScheme(appearance.colorScheme)
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { store.flush() }
        }
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
