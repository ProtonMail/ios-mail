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

import ProtonCoreDataModel
import ProtonInboxRSVP

extension AnswerInvitationUseCase {
    struct UserBasedCurrentUserStorage: CurrentUserStorage {
        private let userManager: UserManager

        init(user: UserManager) {
            userManager = user
        }

        var user: User? {
            .init(
                ID: userManager.userInfo.userId,
                name: nil,
                usedSpace: userManager.userInfo.usedSpace,
                usedBaseSpace: userManager.userInfo.usedBaseSpace,
                usedDriveSpace: userManager.userInfo.usedDriveSpace,
                currency: userManager.userInfo.currency,
                credit: userManager.userInfo.credit,
                maxSpace: userManager.userInfo.maxSpace,
                maxBaseSpace: userManager.userInfo.maxBaseSpace,
                maxDriveSpace: userManager.userInfo.maxDriveSpace,
                maxUpload: userManager.userInfo.maxUpload,
                role: userManager.userInfo.role,
                private: 0,
                subscribed: userManager.userInfo.subscribed,
                services: 0,
                delinquent: userManager.userInfo.delinquent,
                orgPrivateKey: nil,
                email: nil,
                displayName: userManager.userInfo.displayName,
                keys: userManager.userInfo.userKeys
            )
        }
    }
}
