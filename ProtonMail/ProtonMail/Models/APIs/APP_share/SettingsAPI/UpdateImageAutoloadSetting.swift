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

import ProtonCore_DataModel
import ProtonCore_Networking

final class UpdateImageAutoloadSetting: Request {
    enum ImageType {
        case embedded
        case remote

        var parameterName: String {
            switch self {
            case .embedded:
                return "HideEmbeddedImages"
            case .remote:
                return "HideRemoteImages"
            }
        }

        var lastAPIPathComponent: String {
            switch self {
            case .embedded:
                return "hide-embedded-images"
            case .remote:
                return "hide-remote-images"
            }
        }

        var userInfoKeyPath: ReferenceWritableKeyPath<UserInfo, Int> {
            switch self {
            case .embedded:
                return \.hideEmbeddedImages
            case .remote:
                return \.hideRemoteImages
            }
        }
    }

    enum Setting: Int {
        case show = 0
        case hide = 1
    }

    let authCredential: AuthCredential?
    let imageType: ImageType
    let setting: Setting

    var parameters: [String: Any]? {
        [
            imageType.parameterName: setting.rawValue
        ]
    }

    var method: HTTPMethod {
        .put
    }

    var path: String {
        "\(SettingsAPI.path)/\(imageType.lastAPIPathComponent)"
    }

    init(imageType: ImageType, setting: Setting, authCredential: AuthCredential?) {
        self.imageType = imageType
        self.setting = setting
        self.authCredential = authCredential
    }
}
