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

import Combine
import ProtonCoreNetworking
import ProtonCoreServices

extension APIService {
    func perform<Response: Decodable>(request: Request) -> AnyPublisher<Response, Error> {
        var dataTask: URLSessionDataTask?

        return Deferred {
            Future { completion in
                perform(
                    request: request,
                    callCompletionBlockUsing: .immediateExecutor,
                    onDataTaskCreated: { newDataTask in dataTask = newDataTask },
                    decodableCompletion: { _, result in completion(result) }
                )
            }
        }
        .handleEvents(receiveCancel: { dataTask?.cancel() })
        .mapError { $0 }
        .eraseToAnyPublisher()
    }

    func perform(request: Request) -> AnyPublisher<Void, Error> {
        perform(request: request)
            .tryMap { (response: OptionalErrorResponse) in
                try response.validate()
            }
            .eraseToAnyPublisher()
    }
}
