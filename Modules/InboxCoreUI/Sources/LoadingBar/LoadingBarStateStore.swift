import InboxCore
import SwiftUI

@MainActor
final class LoadingBarStateStore: ObservableObject {
    enum Action {
        case startLoading
        case stopLoading
        case cycleCompleted
        case setVisibility(Bool)
    }

    @Published private(set) var isLoading = false

    private let configuration: LoadingBarConfiguration
    private var completedCycles = 0
    private var stopRequested = false
    private var startDate: Date?
    private var targetCyclesAfterStop: Int?
    private var isVisible = false

    init(configuration: LoadingBarConfiguration) {
        self.configuration = configuration
    }

    func handle(action: Action) {
        switch action {
        case .setVisibility(let isVisible):
            self.isVisible = isVisible
        case .startLoading:
            guard !isLoading && isVisible else { return }
            isLoading = true
            completedCycles = 0
            stopRequested = false
            startDate = DateEnvironment.currentDate()
            targetCyclesAfterStop = nil
        case .stopLoading:
            guard isLoading, let start = startDate else {
                stopLoading()
                return
            }

            stopRequested = true

            let currentDate = DateEnvironment.currentDate()

            if shouldStopNowIfOnBoundary(now: currentDate, start: start) {
                stopLoading()
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
                stopLoading()
            }
        }
    }

    // MARK: - Private

    private func stopLoading() {
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
        let remainingTimeInCurrentCycle = Double(requiredCycles) * cycleDuration - elapsedTimeInSeconds

        let needExtraCycle =
            tolerance > 0 && remainingTimeInCurrentCycle > 0 && remainingTimeInCurrentCycle < tolerance && elapsedTimeInSeconds >= cycleDuration
        let extraCycle = needExtraCycle ? 1 : 0

        return requiredCycles + extraCycle
    }

    private func shouldStopNowIfOnBoundary(now: Date, start: Date) -> Bool {
        let elapsed = now.timeIntervalSince(start)
        let cycleDuration = configuration.cycleDuration

        /// Must complete at least one cycle before allowing immediate stop
        guard elapsed >= cycleDuration else {
            return false
        }

        let elapsedCycles = elapsed / cycleDuration
        let fractionalPart = elapsedCycles - floor(elapsedCycles)

        let isNearCycleStart = fractionalPart < configuration.fractionalTolerance
        let isNearCycleEnd = (1.0 - fractionalPart) < configuration.fractionalTolerance

        return isNearCycleStart || isNearCycleEnd
    }
}
