//
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

public enum CommonL10n {
    public static let cancel = LocalizedStringResource("Cancel", bundle: .module)
    public static let close = LocalizedStringResource("Close", bundle: .module)
    public static let confirm = LocalizedStringResource("Confirm", bundle: .module)
    public static let date = LocalizedStringResource("Date", bundle: .module)
    public static let `default` = LocalizedStringResource("Default", bundle: .module)
    public static let delete = LocalizedStringResource("Delete", bundle: .module)
    public static let done = LocalizedStringResource("Done", bundle: .module)
    public static let learnMore = LocalizedStringResource("Learn more", bundle: .module)
    public static let ok = LocalizedStringResource("Ok", bundle: .module)
    public static let on = LocalizedStringResource("On", bundle: .module, comment: "Indicates that a feature is enabled and actively functioning.")
    public static let off = LocalizedStringResource("Off", bundle: .module, comment: "Indicates that a feature is disabled and not functioning.")
    public static let remove = LocalizedStringResource("Remove", bundle: .module)
    public static let save = LocalizedStringResource("Save", bundle: .module)
    public static let time = LocalizedStringResource("Time", bundle: .module)
    public static let undo = LocalizedStringResource("Undo", bundle: .module)
}

public extension LocalizedStringResource.BundleDescription {
    static var module: Self {
        .atURL(Bundle.module.bundleURL)
    }
}
