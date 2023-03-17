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

import CoreData
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services

final class IncomingDefaultService {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func fetchAll(location: IncomingDefaultsAPI.Location, completion: @escaping (Error?) -> Void) {
        fetchAndStoreRecursively(location: location, currentPage: 0, fetchedCount: 0, completion: completion)
    }

    private func fetchAndStoreRecursively(
        location: IncomingDefaultsAPI.Location,
        currentPage: Int,
        fetchedCount: Int,
        completion: @escaping (Error?) -> Void
    ) {
        let request = GetIncomingDefaultsRequest(location: location, page: currentPage)

        dependencies.apiService.perform(
            request: request,
            callCompletionBlockUsing: .immediateExecutor
        ) { (_, result: Result<GetIncomingDefaultsResponse, ResponseError>) in
            do {
                let response = try result.get()

                // This check is meant as a circuit breaker in case resources are added or removed on the BE while we are fetching.
                // It's supposed to stop the recursion if we somehow start fetching empty pages way beyond the actual last page.
                let hasFetchedAMeaningfulPage = !response.incomingDefaults.isEmpty

                guard hasFetchedAMeaningfulPage else {
                    completion(nil)
                    return
                }

                var savingError: Error!

                self.dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
                    for dto in response.incomingDefaults {
                        // check if an IncomingDefault for that email is already stored, perhaps it was inserted by the event loop
                        if let existingIncomingDefault = try? self.find(by: dto.email, in: context) {
                            // if it's newer, we should discard the fetched DTO and not overwrite the existing object
                            if existingIncomingDefault.time > dto.time {
                                continue
                            } else {
                                // we need to delete the old resource before storing the new one
                                // the reason is that because `IncomingDefault.email` is Transformable, it doesn't work as a uniqueness constraint
                                context.delete(existingIncomingDefault)
                                self.store(dto: dto, in: context)
                            }
                        } else {
                            self.store(dto: dto, in: context)
                        }
                    }

                    savingError = context.saveUpstreamIfNeeded()
                }

                if let error = savingError {
                    throw error
                }

                let updatedFetchedCount = fetchedCount + response.incomingDefaults.count

                if updatedFetchedCount < response.total {
                    self.fetchAndStoreRecursively(
                        location: location,
                        currentPage: currentPage + 1,
                        fetchedCount: updatedFetchedCount,
                        completion: completion
                    )
                } else {
                    completion(nil)
                }
            } catch {
                completion(error)
            }
        }
    }

    private func find(by emailAddress: String, in context: NSManagedObjectContext) throws -> IncomingDefault? {
        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)

        fetchRequest.predicate = NSPredicate(
            format: "%K == %@",
            IncomingDefault.Attribute.userID.rawValue,
            dependencies.userInfo.userId
        )

        let incomingDefaultsForThisUser = try context.fetch(fetchRequest)

        // `IncomingDefault.email` is stored as ciphertext (see Transformable + StringCryptoTransformer in the datamodel)
        // that makes it impossible for it to be a part of NSPredicate, we need to check for it separately
        let incomingDefaultsMatchingEmail = incomingDefaultsForThisUser.filter { $0.email == emailAddress }
        assert(incomingDefaultsMatchingEmail.count < 2)
        return incomingDefaultsMatchingEmail.first
    }

    private func store(dto: IncomingDefaultDTO, in context: NSManagedObjectContext) {
        let incomingDefault = IncomingDefault(context: context)
        incomingDefault.email = dto.email
        incomingDefault.id = dto.id
        incomingDefault.location = "\(dto.location.rawValue)"
        incomingDefault.time = dto.time
        incomingDefault.userID = dependencies.userInfo.userId
    }

    func deleteAll(location: IncomingDefaultsAPI.Location) throws {
        var result: Result<Void, Error>!

        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)
            fetchRequest.predicate = NSPredicate(
                format: "%K == %@ AND %K == %@",
                IncomingDefault.Attribute.location.rawValue,
                "\(location.rawValue)",
                IncomingDefault.Attribute.userID.rawValue,
                self.dependencies.userInfo.userId
            )

            do {
                try fetchRequest
                    .execute()
                    .forEach(context.delete)

                if let error = context.saveUpstreamIfNeeded() {
                    throw error
                }

                result = .success(())
            } catch {
                result = .failure(error)
            }
        }

        try result.get()
    }
}

extension IncomingDefaultService {
    struct Dependencies {
        let apiService: APIService
        let contextProvider: CoreDataContextProviderProtocol
        let userInfo: UserInfo
    }
}
