import InboxCore
import SwiftUI

@MainActor
final class LoadingBarStateStore: ObservableObject {
    public enum Action {
        case startLoading
        case stopLoading
        case cycleCompleted
    }

    @Published private(set) var isLoading = false

    private let configuration: LoadingBarConfiguration
    private var completedCycles = 0
    private var stopRequested = false
    private var startDate: Date?
    private var targetCyclesAfterStop: Int?

    public init(configuration: LoadingBarConfiguration) {
        self.configuration = configuration
    }

    func handle(action: Action) {
        switch action {
        case .startLoading:
            isLoading = true
            completedCycles = 0
            stopRequested = false
            startDate = DateEnvironment.currentDate()
            targetCyclesAfterStop = nil
        case .stopLoading:
            guard isLoading, let start = startDate else {
                finish()
                return
            }

            stopRequested = true

            let currentDate = DateEnvironment.currentDate()

            if shouldStopNowIfOnBoundary(now: currentDate, start: start) {
                finish()
                return
            }

            let elapsedTimeInSeconds = currentDate.timeIntervalSince(start)
            let requiredCycles = requiredCycles(elapsedTimeInSeconds: elapsedTimeInSeconds)

            targetCyclesAfterStop = max(requiredCycles, completedCycles)
        case .cycleCompleted:
            guard isLoading else { return }

            completedCycles += 1

            guard stopRequested else { return }

            if let targetCycles = targetCyclesAfterStop, completedCycles >= targetCycles {
                finish()
            }
        }
    }

    // MARK: - Private

    private func finish() {
        isLoading = false
        completedCycles = 0
        stopRequested = false
        startDate = nil
        targetCyclesAfterStop = nil
    }

    private func requiredCycles(elapsedTimeInSeconds: TimeInterval) -> Int {
        let cycleDuration = configuration.cycleDuration
        let tolerance = configuration.tolerance

        let requiredCycles = max(1, Int(ceil(elapsedTimeInSeconds / cycleDuration)))
        let toBoundary = Double(requiredCycles) * cycleDuration - elapsedTimeInSeconds
        let needExtraCycle = tolerance > 0 && toBoundary > 0 && toBoundary < tolerance && elapsedTimeInSeconds >= cycleDuration
        let extraCycle = needExtraCycle ? 1 : 0

        return requiredCycles + extraCycle
    }

    private func shouldStopNowIfOnBoundary(now: Date, start: Date) -> Bool {
        let elapsed = now.timeIntervalSince(start)

        /// Must complete at least one cycle before allowing immediate stop
        guard elapsed >= configuration.cycleDuration else {
            return false
        }

        let cycles = elapsed / configuration.cycleDuration
        let fractional = cycles - floor(cycles)
        let boundaryTolerance = 1e-6

        return fractional < boundaryTolerance || (1.0 - fractional) < boundaryTolerance
    }
}
