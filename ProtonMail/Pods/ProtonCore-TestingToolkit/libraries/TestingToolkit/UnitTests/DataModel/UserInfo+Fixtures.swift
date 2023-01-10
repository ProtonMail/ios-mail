//
//  UserInfo+Fixtures.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
//
//  Copyright (c) 2022 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_DataModel

public extension UserInfo {

    static var dummy: UserInfo {
        UserInfo(displayName: nil,
                 hideEmbeddedImages: nil,
                 hideRemoteImages: nil,
                 imageProxy: nil,
                 maxSpace: nil,
                 notificationEmail: nil,
                 signature: nil,
                 usedSpace: nil,
                 userAddresses: nil,
                 autoSC: nil,
                 language: nil,
                 maxUpload: nil,
                 notify: nil,
                 swipeLeft: nil,
                 swipeRight: nil,
                 role: nil,
                 delinquent: nil,
                 keys: nil,
                 userId: nil,
                 sign: nil,
                 attachPublicKey: nil,
                 linkConfirmation: nil,
                 credit: nil,
                 currency: nil,
                 pwdMode: nil,
                 twoFA: nil,
                 enableFolderColor: nil,
                 inheritParentFolderColor: nil,
                 subscribed: nil,
                 groupingMode: nil,
                 weekStart: nil,
                 delaySendSeconds: nil,
                 telemetry: nil,
                 crashReports: nil,
                 conversationToolbarActions: nil,
                 messageToolbarActions: nil,
                 listToolbarActions: nil,
                 referralProgram: nil
        )
    }
}
