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
import NIOHTTP1

struct NetworkRequest: Equatable, Sendable {
    static func == (lhs: NetworkRequest, rhs: NetworkRequest) -> Bool {
        lhs.remoteRequest == rhs.remoteRequest
            && lhs.localPath == rhs.localPath
            && lhs.status == rhs.status
            && lhs.latency == rhs.latency
            && lhs.ignoreQueryParams == rhs.ignoreQueryParams
            && lhs.wildcardMatch == rhs.wildcardMatch
            && lhs.serveOnce == rhs.serveOnce
            && lhs.mimeType == rhs.mimeType
            && lhs.priority == rhs.priority
    }

    let remoteRequest: RemoteRequest
    let localPath: String
    let status: Int
    let latency: Int
    let ignoreQueryParams: Bool
    let wildcardMatch: Bool
    let serveOnce: Bool
    let mimeType: NetworkMockMimeType
    let priority: NetworkMockPriority

    init(
        method: RequestMethod,
        remotePath: String,
        localPath: String,
        status: Int = 200,
        latency: Int = 0,
        ignoreQueryParams: Bool = false,
        wildcardMatch: Bool = false,
        serveOnce: Bool = false,
        mimeType: NetworkMockMimeType = .json,
        priority: NetworkMockPriority = .standard
    ) {
        self.remoteRequest = RemoteRequest(method: method, path: remotePath)
        self.localPath = localPath
        self.status = status
        self.latency = latency
        self.ignoreQueryParams = ignoreQueryParams
        self.wildcardMatch = wildcardMatch
        self.serveOnce = serveOnce
        self.mimeType = mimeType
        self.priority = priority
    }
}
