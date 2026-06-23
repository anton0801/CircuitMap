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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = AppStore()
    @StateObject private var notifications = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(store)
                .environmentObject(notifications)
        }
    }
    
}
