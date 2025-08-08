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

public enum MailSessionParamsFactory {
    public static func make(origin: Origin, apiConfig: ApiConfig) -> MailSessionParams {
        let fileManager = FileManager.default

        // TODO: exclude application support from iCloud backup

        let applicationSupportPath = fileManager.sharedSupportDirectory.path()
        let cachePath = fileManager.sharedCacheDirectory.path()
        AppLogger.logTemporarily(message: "path: \(cachePath)")

        let mailCacheSize = Measurement<UnitInformationStorage>(value: 1, unit: .gigabytes)

        return MailSessionParams(
            origin: origin,
            sessionDir: applicationSupportPath,
            userDir: applicationSupportPath,
            mailCacheDir: cachePath,
            mailCacheSize: mailCacheSize.bytes,
            logDir: cachePath,
            logDebug: true,
            apiEnvConfig: apiConfig,
            appDetails: .mail
        )
    }
}

private extension Measurement<UnitInformationStorage> {
    var bytes: UInt64 {
        .init(converted(to: .bytes).value)
    }
}
