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
import ProtonCoreDataModel
import ProtonCoreServices

// sourcery: mock
typealias UpdateSwipeActionDuringLoginUseCase = UseCase<Void, UpdateSwipeActionDuringLogin.Parameters>

/// This use case updates the swipe action settings of the newly logged-in account's to the same
/// as the current active account. If the account is the first account logs into the app, it will update
/// the cache to stores the actions from the user's setting.
final class UpdateSwipeActionDuringLogin: UpdateSwipeActionDuringLoginUseCase {
    typealias Dependencies = AnyObject & HasSwipeActionCacheProtocol & HasSaveSwipeActionSettingForUsersUseCase

    private struct SwipeInfoHelper {
        let newUserRightSwipeAction: SwipeActionSettingType?
        let newUserLeftSwipeAction: SwipeActionSettingType?
    }

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {
        let info = SwipeInfoHelper(
            newUserRightSwipeAction: SwipeActionSettingType.convertFromServer(
                rawValue: params.newUserInfo.swipeRight
            ),
            newUserLeftSwipeAction: SwipeActionSettingType.convertFromServer(
                rawValue: params.newUserInfo.swipeLeft
            )
        )

        if params.activeUserInfo.userId == params.newUserInfo.userId {
            // Update the swipe action to cache
            dependencies.swipeActionCache.leftToRightSwipeActionType = info.newUserRightSwipeAction
            dependencies.swipeActionCache.rightToLeftSwipeActionType = info.newUserLeftSwipeAction
            callback(.success)
        } else {
            saveRightSwipeAction(info: info) { [weak self] in
                params.newUserInfo.swipeRight = params.activeUserInfo.swipeRight
                self?.saveLeftSwipeAction(info: info) {
                    params.newUserInfo.swipeLeft = params.activeUserInfo.swipeLeft
                    callback(.success)
                }
            }
        }
    }

    private func saveRightSwipeAction(
        info: SwipeInfoHelper,
        completion: @escaping () -> Void
    ) {
        if let currentRightSwipeAction = dependencies.swipeActionCache.leftToRightSwipeActionType,
           currentRightSwipeAction != info.newUserRightSwipeAction {
            dependencies.saveSwipeActionSetting.execute(
                params: .init(preference: .right(currentRightSwipeAction))
            ) { _ in
                completion()
            }
        } else {
            completion()
        }
    }

    private func saveLeftSwipeAction(
        info: SwipeInfoHelper,
        completion: @escaping () -> Void
    ) {
        if let currentLeftSwipeAction = dependencies.swipeActionCache.rightToLeftSwipeActionType,
           currentLeftSwipeAction != info.newUserLeftSwipeAction {
            dependencies.saveSwipeActionSetting.execute(params: .init(preference: .left(currentLeftSwipeAction))) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}

extension UpdateSwipeActionDuringLogin {
    struct Parameters {
        let activeUserInfo: UserInfo
        let newUserInfo: UserInfo
    }
}
