//
//  ObservabilityTimer.swift
//  ProtonCore-Observability - Created on 02.02.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

typealias Ticker = () -> Void

protocol ObservabilityTimer {
    func register(_ ticker: @escaping Ticker)
    func start()
    func stop()
}

class ObservabilityTimerImpl: ObservabilityTimer {

    private let interval: TimeInterval
    private var timer: Timer?
    private var ticker: Ticker?
    private var isRunning: Bool = false

    init(interval: TimeInterval = 15) {
        self.interval = interval
    }

    func register(_ ticker: @escaping Ticker) {
        self.ticker = ticker
    }

    func start() {
        guard ticker != nil else {
            return
        }
        stop()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        guard let timer else {
            return
        }
        isRunning = false
        timer.invalidate()
        self.timer = nil
    }

    func tick() {
        guard let ticker else {
            stop()
            return
        }
        ticker()
    }
}
