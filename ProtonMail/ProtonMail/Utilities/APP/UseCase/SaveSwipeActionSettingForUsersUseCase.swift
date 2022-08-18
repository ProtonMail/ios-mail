// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCore_Networking
import ProtonCore_Services

/// This use case saves the swipe action selection from the user locally in the UserCachedStatus. Then, if
/// the action has to be synced with backend, it sends one or multiple requests to update the swipe action
/// preference for multiple Proton accounts in the backend.
protocol SaveSwipeActionSettingForUsersUseCase: UseCase {
    func execute(preference: SwipeActionPreference, completion: ((Swift.Result<Void, UpdateSwipeActionError>) -> Void)?)
}

enum SwipeActionPreference: Equatable {
    case left(SwipeActionSettingType)
    case right(SwipeActionSettingType)

    var isSyncable: Bool {
        switch self {
        case .left(let action), .right(let action):
            return action.isSyncable
        }
    }
}

enum UpdateSwipeActionError: Error, Equatable {
    /// Unexpected action
    case invalidAction

    /// Swipe preference not saved in backend for at least one account
    case backendSaveError(error: NSError)
}

final class SaveSwipeActionSetting: SaveSwipeActionSettingForUsersUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(
        preference: SwipeActionPreference,
        completion: ((Swift.Result<Void, UpdateSwipeActionError>) -> Void)?
    ) {
        saveSwipePreferenceLocally(preference: preference)
        saveSwipeActionInBackendIfNeeded(preference: preference, completion: completion)
    }

    private func saveSwipePreferenceLocally(preference: SwipeActionPreference) {
        switch preference {
        case .left(let action):
            dependencies.swipeActionCache.rightToLeftSwipeActionType = action
        case .right(let action):
            dependencies.swipeActionCache.leftToRightSwipeActionType = action
        }
    }

    private func saveSwipeActionInBackendIfNeeded(
        preference: SwipeActionPreference,
        completion: ((Swift.Result<Void, UpdateSwipeActionError>) -> Void)?
    ) {
        guard preference.isSyncable else {
            completion?(.success)
            return
        }

        let request: Request?
        switch preference {
        case .left(let action):
            request = SwipeLeftRequest(action: action)
        case .right(let action):
            request = SwipeRightRequest(action: action)
        }

        guard let request = request else {
            completion?(.failure(.invalidAction))
            return
        }

        let group = DispatchGroup()
        var lastError: NSError?
        dependencies.usersApiServices.forEach({ apiService in
            group.enter()
            apiService.exec(
                route: request,
                responseObject: VoidResponse()
            ) { _, response in
                if let error = response.error?.toNSError {
                    lastError = error
                }
                group.leave()
            }
        })

        group.notify(queue: .main) {
            if let lastError = lastError {
                completion?(.failure(.backendSaveError(error: lastError)))
            } else {
                completion?(.success)
            }
        }
    }
}

extension SaveSwipeActionSetting {

    struct Dependencies {
        let swipeActionCache: SwipeActionCacheProtocol
        let usersApiServices: [APIService]

        init(
            swipeActionCache: SwipeActionCacheProtocol = userCachedStatus,
            usersApiServices: [APIService]
        ) {
            self.swipeActionCache = swipeActionCache
            self.usersApiServices = usersApiServices
        }
    }
}
