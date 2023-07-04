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

import Foundation

enum ConnectionStatus: Int {
    case initialize,
         connected,
         connectedViaCellular,
         connectedViaCellularWithoutInternet,
         connectedViaEthernet,
         connectedViaEthernetWithoutInternet,
         connectedViaWiFi,
         connectedViaWiFiWithoutInternet,
         notConnected

    var isConnected: Bool {
        switch self {
        case .connected, .connectedViaCellular, .connectedViaEthernet, .connectedViaWiFi:
            return true
        case .initialize,
                .notConnected,
                .connectedViaWiFiWithoutInternet,
                .connectedViaCellularWithoutInternet,
                .connectedViaEthernetWithoutInternet:
            return false
        }
    }
}

enum ConnectionFailedReason {
    case timeout
    case internetIssue
}
