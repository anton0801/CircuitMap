import Foundation

final class Rig {
    let etch: Etch
    let meter: Meter
    let relay: Relay
    let breaker: Breaker

    init(etch: Etch, meter: Meter, relay: Relay, breaker: Breaker) {
        self.etch = etch
        self.meter = meter
        self.relay = relay
        self.breaker = breaker
    }

    static func soldered() -> Rig {
        Rig(
            etch: CopperEtch(),
            meter: MultiMeter(),
            relay: BusRelay(),
            breaker: PanelBreaker()
        )
    }
}

@MainActor
final class Bench {

    static let shared = Bench()

    private var sockets: [String: Any] = [:]

    private init() {}

    func plug<T>(_ instance: T, as type: T.Type) {
        sockets[String(describing: type)] = instance
    }

    func wire<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        if let instance = sockets[key] as? T {
            return instance
        }
        let built = assemble(type)
        sockets[key] = built
        return built
    }

    private func assemble<T>(_ type: T.Type) -> T {
        switch String(describing: type) {
        case String(describing: Rig.self):
            return Rig.soldered() as! T
        case String(describing: Tracer.self):
            return Tracer(rig: wire(Rig.self)) as! T
        default:
            fatalError("Bench: no builder for \(type)")
        }
    }
}
