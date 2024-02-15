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

struct AsyncOperationErrorHandler {
    typealias Dependencies = AnyObject & HasInternetConnectionStatusProviderProtocol

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func onOperationError(_ error: NSError) -> ErrorResolution {
        isNetworkConnectionProblem(error: error) ? .pause : .abort
    }

    private func isNetworkConnectionProblem(error: NSError) -> Bool {
        TaskCompletionHelper().calculateIsInternetIssue(
            error: error,
            currentNetworkStatus: dependencies.internetConnectionStatusProvider.status
        )
    }

    enum ErrorResolution {
        case pause
        case abort
    }
}
