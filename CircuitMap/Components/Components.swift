//
//  Components.swift
//  CircuitMap
//
//  Reusable themed UI primitives: buttons, cards, gauges, badges, stats,
//  chips, section headers, empty states and a disclaimer banner.
//

import SwiftUI

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: {
            guard enabled else { return }
            let gen = UIImpactFeedbackGenerator(style: .medium); gen.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).font(Theme.heading(16))
            }
            .foregroundColor(Theme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .fill(Theme.primaryGradient)
            )
            .shadow(color: Theme.sparkGlow, radius: pressed ? 4 : 12, x: 0, y: 4)
            .opacity(enabled ? 1 : 0.4)
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!enabled)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = true } }
            .onEnded { _ in withAnimation(.easeOut(duration: 0.18)) { pressed = false } })
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: {
            let gen = UIImpactFeedbackGenerator(style: .light); gen.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).font(Theme.heading(15))
            }
            .foregroundColor(Theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .fill(Theme.secondaryFill)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
                        .stroke(Theme.border, lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DangerButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).font(Theme.heading(15))
            }
            .foregroundColor(Theme.dangerText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.overload))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Small pill-style icon button used in toolbars.
struct PillButton: View {
    let title: String
    let systemImage: String
    var tint: Color = Theme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title).font(Theme.caption(13))
            }
            .foregroundColor(tint)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Capsule().fill(Theme.card)
                    .overlay(Capsule().stroke(tint.opacity(0.5), lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Card

struct Card<Content: View>: View {
    var padding: CGFloat = Theme.Space.m
    var glow: Color? = nil
    let content: () -> Content

    init(padding: CGFloat = Theme.Space.m, glow: Color? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.glow = glow
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .fill(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
                        .stroke(Theme.border, lineWidth: 1))
            )
            .shadow(color: glow ?? Theme.shadow.opacity(0.5), radius: glow == nil ? 6 : 10, x: 0, y: 4)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var accent: Color = Theme.primary

    var body: some View {
        HStack(spacing: 8) {
            if let s = systemImage {
                Image(systemName: s).foregroundColor(accent).font(.system(size: 14, weight: .bold))
            }
            Text(title.uppercased())
                .font(Theme.caption(12))
                .tracking(1.5)
                .foregroundColor(Theme.textSecond)
            Spacer()
        }
    }
}

// MARK: - Mono stat (watts / amps)

struct MonoStat: View {
    let value: String
    let label: String
    var color: Color = Theme.mono

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Theme.numeric(20, weight: .bold))
                .foregroundColor(color)
            Text(label.uppercased())
                .font(Theme.caption(10))
                .tracking(1)
                .foregroundColor(Theme.textMuted)
        }
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    let status: LoadStatus

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.icon).font(.system(size: 10, weight: .bold))
            Text(status.rawValue.uppercased()).font(Theme.caption(10)).tracking(0.8)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(status.color.opacity(0.15)))
        .overlay(Capsule().stroke(status.color.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Load gauge (horizontal bar)

struct LoadGauge: View {
    /// 0...n where 1.0 is full breaker capacity.
    let usage: Double
    let status: LoadStatus

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.bgDeep)
                Capsule()
                    .fill(LinearGradient(colors: [status.color.opacity(0.7), status.color],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, min(1.0, usage) * geo.size.width))
                    .shadow(color: status.color.opacity(0.5), radius: 4)
                // overload marker tick at 100%
                Rectangle()
                    .fill(Theme.text.opacity(0.25))
                    .frame(width: 1)
                    .offset(x: geo.size.width - 1)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Circular gauge

struct RingGauge: View {
    let fraction: Double          // 0...n
    let color: Color
    var lineWidth: CGFloat = 10
    var label: String
    var sublabel: String

    var body: some View {
        ZStack {
            Circle().stroke(Theme.bgDeep, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(1.0, max(0, fraction))))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 5)
            VStack(spacing: 2) {
                Text(label).font(Theme.numeric(22, weight: .bold)).foregroundColor(Theme.mono)
                Text(sublabel.uppercased()).font(Theme.caption(9)).tracking(1).foregroundColor(Theme.textMuted)
            }
        }
    }
}

// MARK: - Chip

struct Chip: View {
    let title: String
    var systemImage: String? = nil
    let selected: Bool
    var accent: Color = Theme.primary
    let action: () -> Void

    var body: some View {
        Button(action: {
            let gen = UISelectionFeedbackGenerator(); gen.selectionChanged()
            action()
        }) {
            HStack(spacing: 6) {
                if let s = systemImage { Image(systemName: s).font(.system(size: 12, weight: .semibold)) }
                Text(title).font(Theme.caption(13))
            }
            .foregroundColor(selected ? Theme.primaryText : Theme.textSecond)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(selected ? accent : Theme.card)
                    .overlay(Capsule().stroke(selected ? accent : Theme.border, lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty state

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 42, weight: .light))
                .foregroundColor(Theme.textMuted)
            Text(title).font(Theme.heading(17)).foregroundColor(Theme.text)
            Text(message)
                .font(Theme.body(14))
                .foregroundColor(Theme.textSecond)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

// MARK: - Disclaimer banner

struct DisclaimerBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundColor(Theme.copperHi)
            Text("Reference tool only — does not replace a licensed electrician's design.")
                .font(Theme.caption(11))
                .foregroundColor(Theme.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.copper.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.copper.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Labeled field container

struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Theme.caption(11)).tracking(1)
            .foregroundColor(Theme.textMuted)
    }
}

/// A themed text field row.
struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .font(Theme.body(15))
            .foregroundColor(Theme.text)
            .keyboardType(keyboard)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgDeep))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.border, lineWidth: 1))
    }
}

/// A stepper with mono value display.
struct ValueStepper: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...99
    var step: Int = 1
    var unit: String = ""

    var body: some View {
        HStack {
            Text(label).font(Theme.body(14)).foregroundColor(Theme.text)
            Spacer()
            HStack(spacing: 14) {
                stepButton("minus") { value = max(range.lowerBound, value - step) }
                Text("\(value)\(unit)")
                    .font(Theme.numeric(16))
                    .foregroundColor(Theme.mono)
                    .frame(minWidth: 44)
                stepButton("plus") { value = min(range.upperBound, value + step) }
            }
        }
    }

    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: {
            let g = UISelectionFeedbackGenerator(); g.selectionChanged(); action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.primary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Theme.card).overlay(Circle().stroke(Theme.border, lineWidth: 1)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
