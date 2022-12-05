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

import Foundation
@testable import ProtonMail

final class MockFetchMessageDetail: FetchMessageDetailUseCase {
    private(set) var executionTime: Int = 0
    var result: Swift.Result<MessageEntity, Error>

    init(stubbedResult: Swift.Result<MessageEntity, Error>) {
        result = stubbedResult
    }

    override func executionBlock(params: FetchMessageDetail.Params, callback: @escaping NewUseCase<FetchMessageDetail.Output, FetchMessageDetail.Params>.Callback) {
        executionTime += 1
        callback(result)
    }
}
