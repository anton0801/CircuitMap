import Foundation

struct Netlist {

    func next(reading net: Net) -> Hop? {
        if net.soldered { return nil }

        if pushWaiting() { return .tap }

        if !net.signalPresent { return .idle }

        if net.organicFloat && net.floating && !net.recharged { return .recharge }

        return .energize
    }

    private func pushWaiting() -> Bool {
        guard let url = UserDefaults.standard.string(forKey: RailKey.pushURL) else { return false }
        return !url.isEmpty
    }
}
