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

typealias CleanCacheUseCase = UseCase<Void, Void>

final class CleanCache: CleanCacheUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Void, callback: @escaping UseCase<Void, Void>.Callback) {
        SystemLogger.log(message: "cleaning cache")
        var lastError: NSError?
        let group = DispatchGroup()
        for user in dependencies.usersManager.users {
            group.enter()
            user.cleanUserLocalMessages.execute(params: .init(userId: user.userID)) { result in
                if let error = result.error {
                    SystemLogger.log(error: error)
                }
                user.conversationService.cleanAll()
                user.conversationService.fetchConversations(
                    for: Message.Location.inbox.labelID,
                    before: 0,
                    unreadOnly: false,
                    shouldReset: false
                ) { result in
                    switch result {
                    case .failure(let error):
                        lastError = error as NSError
                    case .success:
                        break
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: executionQueue) {
            self.dependencies.imageProxyCache.purge()
            if let error = lastError {
                callback(.failure(error))
            } else {
                callback(.success(()))
            }
        }
    }
}

extension CleanCache {

    struct Dependencies {
        let usersManager: UsersManager
        let imageProxyCache: ImageProxyCacheProtocol
    }
}
