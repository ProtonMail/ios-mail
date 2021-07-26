//
//  UserInfo+Fixtures.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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
                 maxSpace: nil,
                 notificationEmail: nil,
                 signature: nil,
                 usedSpace: nil,
                 userAddresses: nil,
                 autoSC: nil,
                 language: nil,
                 maxUpload: nil,
                 notify: nil,
                 showImage: nil,
                 swipeL: nil,
                 swipeR: nil,
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
                 weekStart: nil)
    }

    func updated(displayName: String? = nil,
                 maxSpace: Int64? = nil,
                 notificationEmail: String? = nil,
                 signature: String? = nil,
                 usedSpace: Int64? = nil,
                 userAddresses: [Address]? = nil,
                 autoSC: Int? = nil,
                 language: String? = nil,
                 maxUpload: Int64? = nil,
                 notify: Int? = nil,
                 showImage: Int? = nil,
                 swipeL: Int? = nil,
                 swipeR: Int? = nil,
                 role: Int? = nil,
                 delinquent: Int? = nil,
                 keys: [Key]? = nil,
                 userId: String? = nil,
                 sign: Int? = nil,
                 attachPublicKey: Int? = nil,
                 linkConfirmation: String? = nil,
                 credit: Int? = nil,
                 currency: String? = nil,
                 pwdMode: Int? = nil,
                 twoFA: Int? = nil,
                 enableFolderColor: Int? = nil,
                 inheritParentFolderColor: Int? = nil,
                 subscribed: Int? = nil,
                 groupingMode: Int? = nil,
                 weekStart: Int? = nil) -> UserInfo {

        UserInfo(displayName: displayName ?? self.displayName,
                 maxSpace: maxSpace ?? self.maxSpace,
                 notificationEmail: notificationEmail ?? self.notificationEmail,
                 signature: signature ?? self.defaultSignature,
                 usedSpace: usedSpace ?? self.usedSpace,
                 userAddresses: userAddresses ?? self.userAddresses,
                 autoSC: autoSC ?? self.autoSaveContact,
                 language: language ?? self.language,
                 maxUpload: maxUpload ?? self.maxUpload,
                 notify: notify ?? self.notify,
                 showImage: showImage ?? self.showImages.rawValue,
                 swipeL: swipeL ?? self.swipeLeft,
                 swipeR: swipeR ?? self.swipeRight,
                 role: role ?? self.role,
                 delinquent: delinquent ?? self.delinquent,
                 keys: keys ?? self.userKeys,
                 userId: userId ?? self.userId,
                 sign: sign ?? self.sign,
                 attachPublicKey: attachPublicKey ?? self.attachPublicKey,
                 linkConfirmation: linkConfirmation ?? self.linkConfirmation.rawValue,
                 credit: credit ?? self.credit,
                 currency: currency ?? self.currency,
                 pwdMode: pwdMode ?? self.passwordMode,
                 twoFA: twoFA ?? self.twoFactor,
                 enableFolderColor: enableFolderColor ?? self.enableFolderColor,
                 inheritParentFolderColor: inheritParentFolderColor ?? self.inheritParentFolderColor,
                 subscribed: subscribed ?? self.subscribed,
                 groupingMode: groupingMode ?? self.groupingMode,
                 weekStart: weekStart ?? self.weekStart)
    }
}
