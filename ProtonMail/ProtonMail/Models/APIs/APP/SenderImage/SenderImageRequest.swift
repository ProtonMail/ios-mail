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

import ProtonCoreNetworking

final class SenderImageRequest: Request {
    enum Size: Int {
        case small = 32
        case medium = 64
        case large = 128

        init(scale: CGFloat) {
            if scale <= 1.0 {
                self = .small
            } else if scale >= 3.0 {
                self = .large
            } else {
                self = .medium
            }
        }
    }

    let method: HTTPMethod = .get
    /// the value of sessionUID. This value should be only used by un-auth api call.
    let uid: String?
    let emailAddress: String
    let size: Size?
    let isDarkMode: Bool
    /// value from the Message/Conversation model
    let bimiSelector: String?

    var path: String {
        guard var urlComponents = URLComponents(string: "/core/v4/images/logo") else {
            return ""
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "Address", value: emailAddress),
            URLQueryItem(name: "Mode", value: isDarkMode ? "dark" : "light")
        ]
        if let size {
            urlComponents.queryItems?.append(URLQueryItem(name: "Size", value: String(size.rawValue)))
        }
        if let bimiSelector = self.bimiSelector {
            urlComponents.queryItems?.append(URLQueryItem(name: "BimiSelector", value: bimiSelector))
        }
        if let uid {
            urlComponents.queryItems?.append(URLQueryItem(name: "UID", value: uid))
        }
        urlComponents.queryItems?.append(URLQueryItem(name: "Format", value: "png"))

        /*
         Apple adheres to an RFC and do not encode `+` in query.
         This is technically in violation of a W3C spec: https://www.w3.org/MarkUp/html-spec/html-spec_8.html#SEC8.2.1
         and is also causing issues on the BE.
         Apple support recommends doing that part manually: https://stackoverflow.com/a/27724627
         */
        urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?.replacingOccurrences(
            of: "+", with: "%2B"
        )

        return urlComponents.url?.absoluteString ?? ""
    }

    init(
        email: String,
        uid: String? = nil,
        isDarkMode: Bool,
        size: Size? = nil,
        bimiSelector: String? = nil
    ) {
        self.emailAddress = email
        self.uid = uid
        self.size = size
        self.isDarkMode = isDarkMode
        self.bimiSelector = bimiSelector
    }
}
