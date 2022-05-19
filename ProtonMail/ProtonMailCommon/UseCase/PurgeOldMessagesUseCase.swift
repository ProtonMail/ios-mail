// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import CoreData
import Foundation

protocol PurgeOldMessagesUseCase: UseCase {
    func execute(completion: @escaping UseCaseResult<Void>)
}

final class PurgeOldMessages: PurgeOldMessagesUseCase {
    private let params: Parameters
    private let dependencies: Dependencies

    convenience init(user: UserManager, coreDataService: CoreDataContextProviderProtocol) {
        let userID = user.userInfo.userId
        let fetchMessageMetaData = FetchMessageMetaData(
            params: .init(userID: userID),
            dependencies: .init(messageDataService: user.messageService,
                                contextProvider: coreDataService))
        self.init(params: .init(userID: userID),
                  dependencies: .init(coreDataService: coreDataService,
                                      fetchMessageMetaData: fetchMessageMetaData))
    }

    init(params: Parameters, dependencies: Dependencies) {
        self.params = params
        self.dependencies = dependencies
    }

    func execute(completion: @escaping UseCaseResult<Void>) {
        self.queryMessagesWithoutMetaData { [weak self] ids, error in
            guard let self = self else {
                completion(.success(Void()))
                return
            }
            if let error = error {
                completion(.failure(error))
                return
            }
            self.dependencies
                .fetchMessageMetaData
                .execute(with: ids, callback: completion)
        }
    }
}

// MARK: Private functions
extension PurgeOldMessages {
    private func queryMessagesWithoutMetaData(completion: @escaping ([MessageID], Error?) -> Void) {
        let context = self.dependencies.coreDataService.rootSavingContext
        let userID = self.params.userID
        self.dependencies.coreDataService.enqueue(context: context) { context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 0) AND %K == %@", Message.Attributes.messageStatus, Contact.Attributes.userID, userID)
            do {
                if let badMessages = try context.fetch(fetchRequest) as? [Message] {
                    let ids = badMessages.map { MessageID($0.messageID) }
                    completion(ids, nil)
                }
            } catch {
                completion([], error)
            }
        }
    }
}

// MARK: Appendix struct definition
extension PurgeOldMessages {
    struct Parameters {
        let userID: String
    }

    struct Dependencies {
        let coreDataService: CoreDataContextProviderProtocol
        let fetchMessageMetaData: FetchMessageMetaDataUseCase

        init(coreDataService: CoreDataContextProviderProtocol,
             fetchMessageMetaData: FetchMessageMetaDataUseCase) {
            self.coreDataService = coreDataService
            self.fetchMessageMetaData = fetchMessageMetaData
        }
    }
}
