//
//  PDFReport.swift
//  CircuitMap
//
//  Generates a multi-section PDF report (schematic summary, loads, materials,
//  safety) with UIGraphicsPDFRenderer. iOS 14 safe.
//

import UIKit

enum PDFReport {

    static func generate(store: AppStore, currencySymbol: String) -> URL? {
        let pageW: CGFloat = 595  // A4 @72dpi
        let pageH: CGFloat = 842
        let margin: CGFloat = 40
        let bounds = CGRect(x: 0, y: 0, width: pageW, height: pageH)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CircuitMap-Report.pdf")

        do {
            try renderer.writePDF(to: url) { ctx in
                var y: CGFloat = margin
                ctx.beginPage()

                func newPageIfNeeded(_ needed: CGFloat) {
                    if y + needed > pageH - margin {
                        ctx.beginPage()
                        y = margin
                    }
                }

                func text(_ string: String, font: UIFont, color: UIColor = .black, x: CGFloat = margin) {
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                    let rect = CGRect(x: x, y: y, width: pageW - x - margin, height: font.lineHeight + 4)
                    string.draw(in: rect, withAttributes: attrs)
                    y += font.lineHeight + 4
                }

                func row(_ cols: [String], widths: [CGFloat], font: UIFont, color: UIColor = .black) {
                    var x = margin
                    for (i, c) in cols.enumerated() {
                        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                        let rect = CGRect(x: x, y: y, width: widths[i], height: font.lineHeight + 2)
                        c.draw(in: rect, withAttributes: attrs)
                        x += widths[i]
                    }
                    y += font.lineHeight + 4
                }

                func divider() {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: margin, y: y))
                    path.addLine(to: CGPoint(x: pageW - margin, y: y))
                    UIColor(white: 0.8, alpha: 1).setStroke()
                    path.lineWidth = 0.5
                    path.stroke()
                    y += 10
                }

                let title = UIFont.systemFont(ofSize: 24, weight: .heavy)
                let h2 = UIFont.systemFont(ofSize: 15, weight: .bold)
                let body = UIFont.systemFont(ofSize: 11, weight: .regular)
                let mono = UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold)

                // Header
                text("Circuit Map — Electrical Plan", font: title, color: UIColor(hex: 0xB8860B))
                text("Reference report · \(Fmt.dateStr(Date()))", font: body, color: .darkGray)
                y += 6
                divider()

                // Supply
                let s = store.supply
                text("Supply", font: h2)
                text("• \(s.phase.rawValue), \(s.voltage) V · Main breaker \(s.mainBreaker) A · Standard \(s.standard.rawValue)", font: body)
                let totals = store.houseTotals()
                text("• House load \(Fmt.watts(totals.totalWatts)) · \(Fmt.amps(totals.totalCurrent)) · Headroom \(Fmt.percent(max(0, totals.headroom)))", font: body)
                y += 6
                divider()

                // Circuits table
                text("Circuits & Loads", font: h2)
                let widths: [CGFloat] = [120, 70, 60, 80, 70, 75]
                row(["Name", "Type", "Breaker", "Load", "Current", "Status"], widths: widths, font: UIFont.systemFont(ofSize: 11, weight: .bold))
                for load in store.loads() {
                    newPageIfNeeded(20)
                    let statusColor: UIColor = load.status == .overload ? UIColor(hex: 0xCC2222)
                        : (load.status == .tight ? UIColor(hex: 0xB8860B) : UIColor(hex: 0x227722))
                    row([load.circuit.name,
                         load.circuit.kind.rawValue,
                         "\(load.circuit.breakerRating) A",
                         Fmt.watts(load.totalWatts),
                         Fmt.amps(load.current),
                         load.status.rawValue],
                        widths: widths, font: mono, color: statusColor)
                }
                y += 6
                divider()

                // Materials
                newPageIfNeeded(120)
                text("Materials specification", font: h2)
                text("• Breakers: \(store.circuits.count)", font: body)
                let totalCable = store.circuits.reduce(0) { $0 + $1.cableLength }
                text("• Cable: \(Int(totalCable)) m total", font: body)
                for c in store.circuits {
                    text("   – \(c.name): \(Int(c.cableLength)) m × \(ElectricalReference.areaLabel(c.cableArea)) (\(c.cableType.rawValue))", font: body, color: .darkGray)
                }
                let sockets = store.points.filter { $0.kind == .socket || $0.kind == .output }.reduce(0) { $0 + $1.count }
                let switches = store.points.filter { $0.kind == .light }.reduce(0) { $0 + $1.count }
                text("• Sockets / outputs: \(sockets) · Switches: \(switches)", font: body)
                y += 6
                divider()

                // Safety
                if !store.notes.isEmpty {
                    newPageIfNeeded(80)
                    text("Safety notes", font: h2)
                    for note in store.notes {
                        newPageIfNeeded(18)
                        let mark = note.resolved ? "[x]" : (note.flagged ? "[!]" : "[ ]")
                        text("\(mark) \(note.text)  (\(note.zone))", font: body)
                    }
                    y += 6
                    divider()
                }

                // Footer
                newPageIfNeeded(40)
                text("Reference tool only — does not replace a licensed electrician's design.",
                     font: UIFont.systemFont(ofSize: 9, weight: .regular), color: .gray)
            }
            return url
        } catch {
            return nil
        }
    }
}
