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

func generateUnhandledRemoteRequestResponse(header: HTTPRequestHead) -> Data {
    let mockResponse = """
            {
                "error": "ROUTE_NOT_FOUND",
                "cause": "No route found for '\(header.uri)'."
            }
        """

    return Data(mockResponse.data(using: .utf8)!)
}

func generateAssetNotFoundResponse(localPath: String) -> Data {
    let mockResponse = """
            {
                "error": "ASSET_NOT_FOUND",
                "cause": "No local asset found at path '\(localPath)'."
            }
        """

    return Data(mockResponse.data(using: .utf8)!)
}
