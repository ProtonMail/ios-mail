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

// sourcery: mock
protocol RefetchAllBlockedSendersUseCase {
    func execute(completion: @escaping (Error?) -> Void)
}

final class RefetchAllBlockedSenders: RefetchAllBlockedSendersUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(completion: @escaping (Error?) -> Void) {
        do {
            try dependencies.incomingDefaultService.hardDelete(query: .location(.blocked))

            dependencies.incomingDefaultService.fetchAll(location: .blocked, completion: completion)
        } catch {
            completion(error)
        }
    }
}

extension RefetchAllBlockedSenders {
    struct Dependencies {
        let incomingDefaultService: IncomingDefaultServiceProtocol
    }
}
