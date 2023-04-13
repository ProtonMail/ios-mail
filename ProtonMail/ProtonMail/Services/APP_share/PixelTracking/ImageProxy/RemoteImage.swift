// Copyright (c) 2022 Proton AG
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

import Alamofire

struct RemoteImage: Codable {
    let contentType: String?
    let data: Data
    let trackerProvider: String?

    init(data: Data, httpURLResponse: HTTPURLResponse) {
        contentType = Self.determineContentType(headers: httpURLResponse.headers)
        self.data = data
        trackerProvider = httpURLResponse.headers["x-pm-tracker-provider"]
    }

    private static func determineContentType(headers: HTTPHeaders) -> String? {
        guard let contentType = headers["Content-Type"] else {
            assertionFailure("Content-Type not declared")
            return nil
        }

        if contentType.components(separatedBy: "/").first != "image" {
            assertionFailure("\(contentType) does not describe an image")
        }

        return contentType
    }
}
