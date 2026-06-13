//
//  CircuitBackground.swift
//  CircuitMap
//
//  Reusable dark backdrop with a faint electric-yellow circuit-trace grid
//  and node dots. Pure Shape/Path (iOS 14 safe, no Canvas).
//

import SwiftUI

/// A schematic grid of right-angled "traces" with node dots at intersections.
struct CircuitTrace: Shape {
    var spacing: CGFloat = 46

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cols = Int(rect.width / spacing) + 2
        let rows = Int(rect.height / spacing) + 2

        // Vertical traces
        for c in 0..<cols {
            let x = CGFloat(c) * spacing
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: rect.height))
        }
        // Horizontal traces
        for r in 0..<rows {
            let y = CGFloat(r) * spacing
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return p
    }
}

/// Node dots placed at a subset of grid intersections.
struct CircuitNodes: Shape {
    var spacing: CGFloat = 46
    var radius: CGFloat = 2.2

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cols = Int(rect.width / spacing) + 1
        let rows = Int(rect.height / spacing) + 1
        for c in 0...cols {
            for r in 0...rows {
                // sparse, deterministic pattern
                if (c + r) % 3 == 0 {
                    let x = CGFloat(c) * spacing
                    let y = CGFloat(r) * spacing
                    p.addEllipse(in: CGRect(x: x - radius, y: y - radius,
                                            width: radius * 2, height: radius * 2))
                }
            }
        }
        return p
    }
}

struct CircuitBackground: View {
    var animated: Bool = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    CircuitTrace(spacing: 46)
                        .stroke(Theme.primary.opacity(0.05), lineWidth: 0.8)
                    CircuitNodes(spacing: 46, radius: 2)
                        .fill(Theme.circuit.opacity(animated ? (pulse ? 0.18 : 0.08) : 0.10))
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()

            // soft top glow
            RadialGradient(colors: [Theme.sparkGlow.opacity(0.10), .clear],
                           center: .top, startRadius: 0, endRadius: 380)
                .ignoresSafeArea()
        }
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
        .onDisappear { pulse = false }
    }
}
