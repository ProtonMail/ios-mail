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

struct ApplicationServices {
    var setUpServices: [ApplicationServiceSetUp] = []
    var willEnterForegroundServices: [ApplicationServiceWillEnterForeground] = []
    var didEnterBackgroundServices: [ApplicationServiceDidEnterBackground] = []
    var terminateServices: [ApplicationServiceTerminate] = []

    @MainActor
    func setUp() {
        setUpServices.forEach { $0.setUpService() }
    }

    func willEnterForeground() {
        willEnterForegroundServices.forEach { $0.willEnterForeground() }
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

protocol ApplicationServiceDidEnterBackground {
    func didEnterBackground()
}
