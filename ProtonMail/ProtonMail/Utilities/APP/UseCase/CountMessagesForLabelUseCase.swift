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
        let request = FetchMessagesByLabelRequest(
            labelID: params.labelID.rawValue,
            endTime: params.endTime,
            isUnread: params.isUnread
        )
        dependencies
            .apiService
            .perform(request: request) { _, result in
                switch result {
                case .failure(let error):
                    callback(.failure(error))
                case .success(let dict):
                    do {
                        let data = try JSONSerialization.data(withJSONObject: dict)
                        let res = try JSONDecoder().decode(MessageResponse.self, from: data)
                        callback(.success(res.total))
                    } catch {
                        callback(.failure(error))
                    }
                }
            }
    }
}

extension CountMessagesForLabel {
    struct Params {
        let labelID: LabelID
        /// UNIX timestamp to filter messages at or earlier than timestamp
        let endTime: Int
        let isUnread: Bool

        init(
            labelID: LabelID = LabelLocation.allmail.labelID,
            endTime: Int = 0,
            isUnread: Bool = false
        ) {
            self.labelID = labelID
            self.endTime = endTime
            self.isUnread = isUnread
        }
    }

    struct Dependencies {
        let apiService: APIService
    }

    private struct MessageResponse: Codable {
        let total: Int

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case total = "Total"
        }
    }
}
