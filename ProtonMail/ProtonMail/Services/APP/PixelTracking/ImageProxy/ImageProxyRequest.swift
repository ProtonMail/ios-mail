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

import ProtonCore_Networking

struct ImageProxyRequest: Request {
    let path: String

    init(unsafeURL: UnsafeRemoteURL, dryRun: Bool) {
        let encodedImageURL: String = unsafeURL
            .value
            .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? unsafeURL.value
        let basePath = "/core/v4/images?Url=\(encodedImageURL)"
        path = dryRun ? "\(basePath)&DryRun=1" : basePath
    }
}
