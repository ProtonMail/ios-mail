// Copyright (c) 2023 Proton Technologies AG
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

final class BuildSearchIndex {

}

extension BuildSearchIndex {
    struct InterruptReason: OptionSet {
        let rawValue: Int
        static let none = InterruptReason([])
        static let noConnection = InterruptReason(rawValue: 1 << 0)
        /// Has cellular but `download via mobile data` is disabled
        static let noWiFi = InterruptReason(rawValue: 1 << 1)
        static let overHeating = InterruptReason(rawValue: 1 << 2)
        static let lowBattery = InterruptReason(rawValue: 1 << 3)
        static let lowStorage = InterruptReason(rawValue: 1 << 4)

        var stateDescription: String {
            if self.contains(.noConnection) {
                return L11n.EncryptedSearch.download_paused_no_connectivity
            } else if self.contains(.noWiFi) {
                return L11n.EncryptedSearch.download_paused_no_wifi
            } else if self.contains(.lowBattery) {
                return L11n.EncryptedSearch.download_paused_low_battery
            } else if self.contains(.overHeating) {
                // TODO why there is no string for this case
                assertionFailure("Without translation")
                return "Download paused due to over heating"
            } else if self.contains(.lowStorage) {
                return L11n.EncryptedSearch.download_paused_low_storage
            } else if self.contains(.none) {
                return .empty
            } else {
                assertionFailure("Unknown interrupt reason")
                return .empty
            }
        }

        var adviceDescription: String {
            if self.contains(.noConnection) {
                return L11n.EncryptedSearch.download_paused_no_connectivity_advice
            } else if self.contains(.noWiFi) {
                return L11n.EncryptedSearch.download_paused_no_wifi_advice
            } else if self.contains(.lowBattery) {
                return L11n.EncryptedSearch.download_paused_low_battery_advice
            } else if self.contains(.overHeating) {
                // TODO why there is no string for this case
                return "Cool down"
            } else if self.contains(.lowStorage) {
                return L11n.EncryptedSearch.download_paused_low_storage_advice
            } else if self.contains(.none) {
                return .empty
            } else {
                assertionFailure("Unknown interrupt reason")
                return .empty
            }
        }
    }
}
