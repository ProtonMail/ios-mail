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

import Foundation

@MainActor
struct ApplicationServices {
    var setUpServices: [ApplicationServiceSetUp] = []
    var willEnterForegroundServices: [ApplicationServiceWillEnterForeground] = []
    var willResignActiveServices: [ApplicationServiceWillResignActive] = []
    var didEnterBackgroundServices: [ApplicationServiceDidEnterBackground] = []
    var terminateServices: [ApplicationServiceTerminate] = []

    func setUp() {
        setUpServices.forEach { $0.setUpService() }
    }

    func willEnterForeground() {
        willEnterForegroundServices.forEach { $0.willEnterForeground() }
    }

    func willResignActive() {
        willResignActiveServices.forEach { $0.willResignActive() }
    }

    func didEnterBackground() {
        didEnterBackgroundServices.forEach { $0.didEnterBackground() }
    }

    func terminate() {
        terminateServices.forEach { $0.terminateService() }
    }
}

protocol ApplicationServiceSetUp {
    @MainActor
    func setUpService()
}

protocol ApplicationServiceTerminate {
    func terminateService()
}

protocol ApplicationServiceWillEnterForeground {
    func willEnterForeground()
}

@MainActor
protocol ApplicationServiceWillResignActive {
    func willResignActive()
}

protocol ApplicationServiceDidEnterBackground {
    func didEnterBackground()
}
