//
//  SettingsViewModel.swift
//  Proton Mail - Created on 12/12/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_DataModel

enum SettingPrivacyItem: CustomStringConvertible {
    case autoLoadRemoteContent
    case autoLoadEmbeddedImage
    case linkOpeningMode
    case metadataStripping

    var description: String {
        switch self {
        case .autoLoadRemoteContent:
            return LocalString._auto_show_images
        case .autoLoadEmbeddedImage:
            return LocalString._auto_show_embedded_images
        case .linkOpeningMode:
            return LocalString._request_link_confirmation
        case .metadataStripping:
            return LocalString._strip_metadata
        }
    }
}

class SettingsPrivacyViewModel {

    let privacySections: [SettingPrivacyItem] = [.autoLoadRemoteContent,
                                                 .autoLoadEmbeddedImage,
                                                 .linkOpeningMode,
                                                 .metadataStripping]
    private let user: UserManager

    var userInfo: UserInfo {
        return self.user.userInfo
    }

    var isMetadataStripping: Bool {
        get {
            return userCachedStatus.metadataStripping == .stripMetadata
        }
        set {
            userCachedStatus.metadataStripping = newValue ? .stripMetadata : .sendAsIs
        }
    }

    init(user: UserManager) {
        self.user = user
    }

    func updateAutoLoadImageStatus(newStatus: Bool, completion: ((NSError?) -> Void)?) {
        self.user.userService.updateAutoLoadImage(auth: user.auth,
                                                  user: userInfo,
                                                  remote: newStatus) { _, _, error in
            if error == nil {
                self.user.save()
                completion?(nil)
            } else {
                completion?(error)
            }
        }
    }

    func updateLinkConfirmation(newStatus: Bool, completion: ((NSError?) -> Void)?) {
        self.user.userService.updateLinkConfirmation(auth: user.auth,
                                                     user: user.userInfo,
                                                     newStatus ? .confirmationAlert : .openAtWill) { _, _, error in
            if error != nil {
                completion?(error)
            } else {
                self.user.save()
                completion?(nil)
            }
        }
    }

    func updateAutoLoadEmbeddedImageStatus(newStatus: Bool, completion: ((NSError?) -> Void)?) {
        self.user.userService.updateAutoLoadEmbeddedImage(auth: user.auth,
                                                          userInfo: user.userInfo,
                                                          remote: newStatus) { _, _, error in
            if error == nil {
                self.user.save()
                completion?(nil)
            } else {
                completion?(error)
            }
        }
    }
}
