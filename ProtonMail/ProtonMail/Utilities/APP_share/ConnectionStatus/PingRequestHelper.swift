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
import ProtonCoreDoh

enum PingRequestHelper {
    case protonServer, protonStatus

    func urlRequest(timeout: TimeInterval = 3, doh: DoHInterface = BackendConfiguration.shared.doh) -> URLRequest {
        switch self {
        case .protonServer:
            let serverLink = "\(doh.getCurrentlyUsedHostUrl())/core/v4/tests/ping"
            // swiftlint:disable:next force_unwrapping
            let url = URL(string: serverLink)!
            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.httpMethod = "HEAD"
            return request
        case .protonStatus:
            // swiftlint:disable:next force_unwrapping
            let statusPageURL = URL(string: Link.protonStatusPage)!
            var request = URLRequest(url: statusPageURL, timeoutInterval: timeout)
            request.httpMethod = "HEAD"
            return request
        }
    }
}
