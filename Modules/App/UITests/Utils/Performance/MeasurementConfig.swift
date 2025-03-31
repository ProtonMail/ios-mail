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

public final class MeasurementConfig {

    public static var buildCommitShortSha: String = ProcessInfo.processInfo.environment["CI_COMMIT_SHA"] ?? "unknown"
    public static var ciJobId: String = ProcessInfo.processInfo.environment["CI_JOB_ID"] ?? "unknown"
    public static var version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    public static var environment: String = "unknown"
    public static var product: String = Bundle.main.bundleIdentifier ?? "unknown"

    public static var lokiEndpoint: String?
    public static var lokiCertificate: String = ""
    public static var lokiCertificatePassphrase: String = ""
    public static var _bundle: Bundle?

    private init() {}

    @discardableResult
    public static func setEnvironment(_ value: String) -> MeasurementConfig.Type {
        environment = value
        return self
    }

    @discardableResult
    public static func setLokiEndpoint(_ value: String?) -> MeasurementConfig.Type {
        lokiEndpoint = value
        return self
    }

    @discardableResult
    public static func setLokiCertificate(_ value: String) -> MeasurementConfig.Type {
        lokiCertificate = value
        return self
    }

    @discardableResult
    public static func setLokiCertificatePassphrase(_ value: String) -> MeasurementConfig.Type {
        lokiCertificatePassphrase = value
        return self
    }

    @discardableResult
    public static func setBundle(_ bundle: Bundle) -> MeasurementConfig.Type {
        _bundle = bundle
        product = bundle.bundleIdentifier ?? "unknown"
        return self
    }

    @discardableResult
    public static func setAppVersion(_ app_version: String) -> MeasurementConfig.Type {
        version = app_version
        return self
    }
}
