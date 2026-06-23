import Foundation
import Combine

@MainActor
final class Readout: ObservableObject {

    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }

    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }

    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false

    private let tracer: Tracer
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?

    private var uiLocked: Bool = false

    init() {
        self.tracer = Bench.shared.wire(Tracer.self)
        bindCharge()
    }

    deinit {
        deadlineTask?.cancel()
    }

    private func bindCharge() {
        tracer.chargePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] charge in
                self?.handleCharge(charge)
            }
            .store(in: &cancellables)
    }

    func ignite() {
        tracer.warmUp()
        armDeadline()
    }

    func ingestSignal(_ data: [String: Any]) {
        Task {
            tracer.loadSignal(data)
            await tracer.trace()
        }
    }

    func ingestJumpers(_ data: [String: Any]) {
        tracer.loadJumpers(data)
    }

    func acceptConsent() {
        tracer.armBreaker {
            self.showPermissionPrompt = false
        }
    }

    func skipConsent() {
        showPermissionPrompt = false
        tracer.tripBreaker()
    }

    func networkConnectivityChanged(_ connected: Bool) {
        if !connected {
            showOfflineView = true
        }
    }

    private func handleCharge(_ charge: Charge) {
        guard !uiLocked else { return }

        switch charge {
        case .tracing:
            break
        case .askSwitch:
            showPermissionPrompt = true
        case .energized:
            navigateToWeb = true
        case .blown:
            navigateToMain = true
        }
    }

    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)

            guard let self = self else { return }

            if self.tracer.reportOpen() {
                self.handleCharge(.blown)
            }
        }
    }
}
