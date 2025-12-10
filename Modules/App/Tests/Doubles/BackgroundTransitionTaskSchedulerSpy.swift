// Copyright (c) 2025 Proton Technologies AG
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

import UIKit

@testable import ProtonMail

class BackgroundTransitionTaskSchedulerSpy: BackgroundTransitionTaskScheduler {
    var stubbedBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 10)
    private(set) var invokedBeginBackgroundTask: [(taskName: String?, handler: (@MainActor @Sendable () -> Void)?)] = []
    private(set) var invokedEndBackgroundTask: [UIBackgroundTaskIdentifier] = []

    // MARK: - BackgroundTransitionTaskScheduler

    func beginBackgroundTask(
        withName taskName: String?,
        expirationHandler handler: (@MainActor @Sendable () -> Void)?
    ) -> UIBackgroundTaskIdentifier {
        invokedBeginBackgroundTask.append((taskName, handler))

        return stubbedBackgroundTaskIdentifier
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        invokedEndBackgroundTask.append(identifier)
    }
}
