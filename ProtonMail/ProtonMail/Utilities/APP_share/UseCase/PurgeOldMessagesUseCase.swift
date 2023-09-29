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

import CoreData
import Foundation

typealias PurgeOldMessagesUseCase = UseCase<Void, Void>

final class PurgeOldMessages: PurgeOldMessagesUseCase {
    private let dependencies: Dependencies

    convenience init(user: UserManager, coreDataService: CoreDataContextProviderProtocol) {
        let fetchMessageMetaData = user.container.fetchMessageMetaData
        self.init(
            dependencies: .init(
                coreDataService: coreDataService,
                fetchMessageMetaData: fetchMessageMetaData,
                userID: user.userID
            )
        )
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Void, callback: @escaping UseCase<Void, Void>.Callback) {
        queryMessagesWithoutMetaData { [weak self] ids, error in
            guard let self = self else {
                callback(.success(()))
                return
            }
            if let error = error {
                callback(.failure(error))
                return
            }
            self.dependencies
                .fetchMessageMetaData
                .execute(
                    params: .init(messageIDs: ids),
                    callback: { result in
                        switch result {
                        case .success:
                            callback(.success(()))
                        case .failure(let error):
                            callback(.failure(error))
                        }
                    }
                )
        }
    }
}

// MARK: Private functions
extension PurgeOldMessages {
    private func queryMessagesWithoutMetaData(completion: @escaping ([MessageID], Error?) -> Void) {
        self.dependencies.coreDataService.enqueueOnRootSavingContext { context in
            let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(
                format: "(%K == 0) AND %K == %@",
                Message.Attributes.messageStatus,
                Contact.Attributes.userID,
                self.dependencies.userID.rawValue
            )
            do {
                let badMessages = try context.fetch(fetchRequest)
                let ids = badMessages.map { MessageID($0.messageID) }
                completion(ids, nil)
            } catch {
                completion([], error)
            }
        }
    }
}

// MARK: Appendix struct definition
extension PurgeOldMessages {
    struct Dependencies {
        let userID: UserID
        let coreDataService: CoreDataContextProviderProtocol
        let fetchMessageMetaData: FetchMessageMetaDataUseCase

        init(coreDataService: CoreDataContextProviderProtocol,
             fetchMessageMetaData: FetchMessageMetaDataUseCase,
             userID: UserID) {
            self.coreDataService = coreDataService
            self.fetchMessageMetaData = fetchMessageMetaData
            self.userID = userID
        }
    }
}
