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
import ProtonCore_Services

typealias CountMessagesForLabelUseCase = NewUseCase<Int, CountMessagesForLabel.Params>

final class CountMessagesForLabel: CountMessagesForLabelUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        let request = MessageCountRequest()
        dependencies.apiService.perform(
            request: request,
            response: MessageCountResponse()
        ) { _, response in
            if let error = response.error {
                callback(.failure(error))
                return
            }
            guard let count = response.counts else {
                callback(.failure(NSError.unableToParseResponse("Without count")))
                return
            }
            do {
                let result = try JSONDecoder().decode(type: [MessageCount].self, from: count)
                guard let target = result.first(where: { $0.labelID == params.labelID }) else {
                    callback(.failure(NSError.unableToParseResponse("Doesn't include target labelID")))
                    return
                }
                let num = params.isUnread ? target.unread : target.total
                callback(.success(num))
            } catch {
                callback(.failure(error))
            }
        }
    }
}

extension CountMessagesForLabel {
    struct Params {
        let labelID: LabelID
        let isUnread: Bool

        init(
            labelID: LabelID = LabelLocation.allmail.labelID,
            isUnread: Bool = false
        ) {
            self.labelID = labelID
            self.isUnread = isUnread
        }
    }

    struct Dependencies {
        let apiService: APIService
    }
}

private struct MessageCount: Codable {
    let total: Int
    let labelID: LabelID
    let unread: Int

    enum CodingKeys: String, CodingKey {
        case total = "Total"
        case labelID = "LabelID"
        case unread = "Unread"
    }
}

extension JSONDecoder {
    func decode<D: Decodable>(type: D.Type, from arrayDict: [[String: Any]]) throws -> D {
        let jsonData = try JSONSerialization.data(withJSONObject: arrayDict, options: [])
        return try JSONDecoder().decode(type, from: jsonData)
    }
}
