import Foundation
import Combine
import AppsFlyerLib

@MainActor
final class Tracer {

    private var net = Net()
    private var wired = false
    private var fused = false
    private var live = false

    private let rig: Rig
    private let netlist = Netlist()

    private let chargeSubject = PassthroughSubject<Charge, Never>()
    var chargePublisher: AnyPublisher<Charge, Never> {
        chargeSubject.eraseToAnyPublisher()
    }

    private var armTask: Task<Void, Never>?

    init(rig: Rig) {
        self.rig = rig
    }

    private func ensureWired() {
        guard !wired else { return }
        net = Net.rebuild(from: rig.etch.readback())
        wired = true
    }

    private func latch() -> Bool {
        guard !fused else { return false }
        fused = true
        return true
    }

    func warmUp() {
        ensureWired()
    }

    func loadSignal(_ raw: [String: Any]) {
        ensureWired()
        net.signal = raw.mapValues { "\($0)" }
        rig.etch.etch(net.log())
    }

    func loadJumpers(_ raw: [String: Any]) {
        ensureWired()
        net.jumpers = raw.mapValues { "\($0)" }
        rig.etch.etch(net.log())
    }

    func trace() async {
        ensureWired()
        guard !fused, !live else { return }
        live = true
        defer { live = false }

        while let hop = netlist.next(reading: net) {
            switch hop {
            case .tap:
                let pushURL = UserDefaults.standard.string(forKey: RailKey.pushURL) ?? ""
                solder(toURL: pushURL)
                return
            case .idle:
                chargeSubject.send(.tracing)
                return
            case .recharge:
                await recharge()
                continue
            case .energize:
                await energize()
                return
            }
        }
    }

    private func recharge() async {
        net.recharged = true
        rig.etch.etch(net.log())

        try? await Task.sleep(nanoseconds: 5_000_000_000)

        guard !net.soldered else { return }

        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        do {
            var measured = try await rig.meter.measure(deviceID: deviceID)
            for (k, v) in net.jumpers {
                if measured[k] == nil { measured[k] = v }
            }
            net.signal = measured.mapValues { "\($0)" }
            rig.etch.etch(net.log())
        } catch {
            print("\(Rail.logPlug) Recharge re-measure soft fail: \(error)")
        }
    }

    private func energize() async {
        do {
            let url = try await rig.relay.send(payload: net.signal.mapValues { $0 as Any })
            solder(toURL: url)
        } catch {
            blow()
        }
    }

    private func solder(toURL url: String) {
        let needsSwitch = net.breakerDue
        guard latch() else { return }

        net.loadURL = url
        net.loadMode = "Active"
        net.floating = false
        net.soldered = true

        rig.etch.etch(net.log())
        rig.etch.tagLoad(url: url, mode: "Active")
        rig.etch.raisePrimedFlag()
        UserDefaults.standard.removeObject(forKey: RailKey.pushURL)

        chargeSubject.send(needsSwitch ? .askSwitch : .energized)
    }

    private func blow() {
        guard latch() else { return }
        net.soldered = true
        chargeSubject.send(.blown)
    }

    func armBreaker(then ack: @escaping () -> Void) {
        ensureWired()
        armTask = Task { [weak self] in
            guard let self = self else { return }

            let granted = await self.rig.breaker.arm()

            self.net.breakerArmed = granted
            self.net.breakerTripped = !granted
            self.net.breakerSetAt = Date()
            self.rig.etch.etch(self.net.log())

            if granted {
                self.rig.breaker.wireGrid()
            }

            self.chargeSubject.send(.energized)
            ack()
        }
    }

    func tripBreaker() {
        ensureWired()
        net.breakerSetAt = Date()
        rig.etch.etch(net.log())
        chargeSubject.send(.energized)
    }

    func reportOpen() -> Bool {
        return latch()
    }
}
