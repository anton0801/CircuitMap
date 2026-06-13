//
//  CustomTabBar.swift
//  CircuitMap
//
//  Themed bottom tab bar with spark-glow selection.
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case board, rooms, power, log, settings
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .board: return "Board"
        case .rooms: return "Rooms"
        case .power: return "Power"
        case .log: return "Log"
        case .settings: return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .board: return "bolt.square.fill"
        case .rooms: return "square.split.2x2.fill"
        case .power: return "gauge.with.dots.needle.bottom.50percent"
        case .log: return "list.bullet.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            Theme.bgDeep
                .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button(action: {
            let g = UISelectionFeedbackGenerator(); g.selectionChanged()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = tab }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Theme.primary.opacity(0.18))
                            .frame(width: 38, height: 38)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? Theme.primary : Theme.textMuted)
                        .shadow(color: isSelected ? Theme.sparkGlow : .clear, radius: 6)
                }
                .frame(height: 38)
                Text(tab.title)
                    .font(Theme.caption(10))
                    .foregroundColor(isSelected ? Theme.primary : Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
