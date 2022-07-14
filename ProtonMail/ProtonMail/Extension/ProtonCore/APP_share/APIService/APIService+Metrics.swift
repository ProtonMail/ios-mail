// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_Services

extension APIService {

    func metrics(log: String, title: String, data: [String: Any], completion: @escaping CompletionBlock) {
        let path: String = "/core/v4/metrics"
        let parameters = [
            "Log": log,
            "Title": title,
            "Data": data
        ] as [String: Any]
        let headers: [String: Any] = [:]

        self.request(method: .post,
                     path: path,
                     parameters: parameters,
                     headers: headers,
                     authenticated: true,
                     autoRetry: true,
                     customAuthCredential: nil,
                     completion: completion)
    }
}
