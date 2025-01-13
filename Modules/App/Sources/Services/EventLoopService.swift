// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Combine
import Foundation

final class EventLoopService: @unchecked Sendable {
    private var timer: Timer = .init()
    private var appInForeground: Bool = true
    
    private weak var appContext: AppContext?
    private weak var eventLoopProvider: EventLoopProvider?
    
    private var cancellables: Set<AnyCancellable> = .init()

    init(appContext: AppContext, eventLoopProvider: EventLoopProvider) {
        self.appContext = appContext
        self.eventLoopProvider = eventLoopProvider

        appContext
            .$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTimerStatus()
            }
            .store(in: &cancellables)
    }

    private func updateTimerStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard appInForeground, let appContext else {
                invalidateTimer()
                return
            }
            appContext.hasActiveUser ? startTimer() : invalidateTimer()
        }
    }

    private func invalidateTimer() {
        guard timer.isValid else { return }
        timer.invalidate()
    }

    private func startTimer() {
        invalidateTimer()
        timer = .scheduledTimer(
            timeInterval: AppConstants.eventLoopFrequency,
            target: self,
            selector: #selector(executeTask),
            userInfo: nil,
            repeats: true
        )
    }

    @objc
    private func executeTask() {
        eventLoopProvider?.pollEvents()
    }
}

extension EventLoopService: ApplicationServiceDidBecomeActive {

    func becomeActiveService() {
        appInForeground = true
        executeTask()
        updateTimerStatus()
    }
}

extension EventLoopService: ApplicationServiceDidEnterBackground {

    func enterBackgroundService() {
        executeTask()
        appInForeground = false
        updateTimerStatus()
    }
}

protocol EventLoopProvider: AnyObject {

    func pollEvents()
    func pollEventsAsync() async
}
