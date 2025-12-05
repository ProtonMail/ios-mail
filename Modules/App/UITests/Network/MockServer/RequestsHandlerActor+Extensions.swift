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

actor RequestsHandlerActor {
    private var mockedRequests: [NetworkRequest] = []

    func addMockedRequests(_ requests: NetworkRequest...) {
        for request in requests {
            mockedRequests.append(request)
        }
    }

    func matchClientRequestHeader(_ clientRequest: HTTPRequestHead) -> NetworkRequest? {
        return findMatchingRequest(clientRequest: clientRequest)
    }

    func remove(_ request: NetworkRequest) {
        guard let index = mockedRequests.firstIndex(of: request) else {
            return
        }

        mockedRequests.remove(at: index)
    }

    func clear() {
        mockedRequests.removeAll()
    }
}

extension RequestsHandlerActor {
    fileprivate func findMatchingRequest(clientRequest: HTTPRequestHead) -> NetworkRequest? {
        return
            mockedRequests
            .filter { $0.remoteRequest.method == clientRequest.method }
            .sorted { $0.priority > $1.priority }
            .first { mockRequest in
                switch true {
                case mockRequest.ignoreQueryParams && mockRequest.wildcardMatch:
                    return clientRequest.withStrippedQueryParams().wildcardMatches(
                        mockRequest.remoteRequest
                    )
                case mockRequest.ignoreQueryParams:
                    return clientRequest.stripPathQueryParams() == mockRequest.remoteRequest.path
                case mockRequest.wildcardMatch:
                    return clientRequest.wildcardMatches(mockRequest.remoteRequest)
                default:
                    return clientRequest.uri == mockRequest.remoteRequest.path
                }
            }
    }
}

extension HTTPRequestHead {
    fileprivate func withStrippedQueryParams() -> Self {
        return HTTPRequestHead(
            version: self.version,
            method: self.method,
            uri: self.stripPathQueryParams()
        )
    }

    fileprivate func stripPathQueryParams() -> String {
        return self.uri.components(separatedBy: "?").first ?? self.uri
    }

    fileprivate func wildcardMatches(_ request: RemoteRequest) -> Bool {
        let selfPaths = self.uri.split(separator: "/")
        let requestPaths = request.path.split(separator: "/")

        for pathPairs in zip(selfPaths, requestPaths) {
            if pathPairs.0 == "*" || pathPairs.1 == "*" { continue }
            if pathPairs.0 != pathPairs.1 { return false }
        }

        return true
    }
}
