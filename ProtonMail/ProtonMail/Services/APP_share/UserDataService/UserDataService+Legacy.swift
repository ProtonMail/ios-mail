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
import ProtonCore_Keymaker
import ProtonCore_Networking

extension UserDataService {
    @available(
        *,
         deprecated,
         message: "Switch to updateImageAutoloadSetting() once Image Proxy is ready to be shipped."
    )
    func updateAutoLoadImages(
        currentAuth: AuthCredential,
        userInfo: UserInfo,
        flag: ShowImages,
        enable: Bool,
        completion: @escaping UserInfoBlock
    ) {
        guard keymaker.mainKey(by: RandomPinProtection.randomPin) != nil else {
            completion(nil, nil, NSError.lockError())
            return
        }

        var newStatus = userInfo.showImages
        if enable {
            newStatus.insert(flag)
        } else {
            newStatus.remove(flag)
        }

        let api = UpdateShowImages(status: newStatus, authCredential: currentAuth)

        self.apiService.exec(route: api, responseObject: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo.showImages = newStatus
            }
            completion(userInfo, nil, response.error?.toNSError)
        }
    }
}

@available(
    *,
     deprecated,
     message: "Switch to UpdateImageAutoloadSetting once Image Proxy is ready to be shipped."
)
final class UpdateShowImages: Request {
    private let status: ShowImages

    init(status: ShowImages, authCredential: AuthCredential?) {
        self.status = status
        self.authCredential = authCredential
    }

    let authCredential: AuthCredential?

    var parameters: [String: Any]? {
        let out: [String: Int] = ["ShowImages": status.rawValue]
        return out
    }

    var method: HTTPMethod {
        .put
    }

    var path: String {
        SettingsAPI.path + "/images"
    }
}
