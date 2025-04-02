// Copyright (c) 2025 Proton Technologies AG
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
import proton_app_uniffi

struct AppVersionProvider {
    let sdkVersionProvider: SDKVersionProvider

    /// Application and SDK version e.g. 1.18.0 (142) - 1.31.0
    var fullVersion: String { "\(Bundle.main.appVersion) - \(sdkVersionProvider.sdkVersion)" }

    init(sdkVersionProvider: SDKVersionProvider = .production) {
        self.sdkVersionProvider = sdkVersionProvider
    }
}

struct SDKVersionProvider {
    let sdkVersion: String
}

extension SDKVersionProvider {
    static let production: SDKVersionProvider = .init(sdkVersion: rustSdkVersion())
}
