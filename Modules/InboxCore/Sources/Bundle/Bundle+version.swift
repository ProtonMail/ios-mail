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

import Foundation

extension Bundle {

    /// Returns the major version of the app.
    public var bundleShortVersion: String {
        forceCast(infoDictionary?["CFBundleShortVersionString"], String.self)
    }

    /**
     The effectiveAppVersion property returns the public-facing version of the app,
     used for features such as human verification and bug reporting. It ensures that
     the version is never reported as lower than "7.0.1" (the official initial release version).

     Examples:
     - If the version is "0.2.0", effectiveAppVersion returns "7.0.1" (minimum enforced version).
     - If the version is "7.1.1" or "11.0.0", effectiveAppVersion returns the actual version ("7.1.1" or "11.0.0").

     Once the app's internal version naturally reaches or exceeds "7.0.1", this property
     will reflect the real app version, so we can get rid of it and start using bundleShortVersion.
     */
    public var effectiveAppVersion: String {
        bundleShortVersion.compare(
            targetReleaseVersion,
            options: .numeric
        ) == .orderedAscending ? targetReleaseVersion : bundleShortVersion
    }

    // MARK: - Private

    private var targetReleaseVersion: String {
        "7.0.1"
    }

}
