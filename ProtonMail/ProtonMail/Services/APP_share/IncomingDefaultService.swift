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

// sourcery: mock
protocol IncomingDefaultServiceProtocol {
    func fetchAll(location: IncomingDefaultsAPI.Location, completion: @escaping (Error?) -> Void)
    func listLocal(query: IncomingDefaultService.Query) throws -> [IncomingDefaultEntity]
    func save(dto: IncomingDefaultDTO) throws
    func performLocalUpdate(emailAddress: String, newLocation: IncomingDefaultsAPI.Location) throws
    func performRemoteUpdate(
        emailAddress: String,
        newLocation: IncomingDefaultsAPI.Location,
        completion: @escaping (Error?) -> Void
    )
    func delete(query: IncomingDefaultService.Query) throws
}

final class IncomingDefaultService {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension IncomingDefaultService: IncomingDefaultServiceProtocol {
    func fetchAll(location: IncomingDefaultsAPI.Location, completion: @escaping (Error?) -> Void) {
        fetchAndStoreRecursively(location: location, currentPage: 0, fetchedCount: 0, completion: completion)
    }

    func listLocal(query: Query) throws -> [IncomingDefaultEntity] {
        try dependencies.contextProvider.read { context in
            try self.find(query: query, in: context, includeSoftDeleted: false).map(IncomingDefaultEntity.init)
        }
    }

    func save(dto: IncomingDefaultDTO) throws {
        try writeToDatabase { context in
            try self.save(dto: dto, in: context)
        }
    }

    func performLocalUpdate(emailAddress: String, newLocation: IncomingDefaultsAPI.Location) throws {
        try writeToDatabase { context in
            try self.find(query: .email(emailAddress), in: context, includeSoftDeleted: false).forEach(context.delete)

            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.email = emailAddress
            incomingDefault.location = "\(newLocation.rawValue)"
            incomingDefault.time = LocaleEnvironment.currentDate()
            incomingDefault.userID = self.dependencies.userInfo.userId
        }
    }

    func performRemoteUpdate(
        emailAddress: String,
        newLocation: IncomingDefaultsAPI.Location,
        completion: @escaping (Error?) -> Void
    ) {
        let request = AddIncomingDefaultsRequest(location: newLocation, overwrite: true, target: .email(emailAddress))

        dependencies.apiService.perform(
            request: request,
            callCompletionBlockUsing: .immediateExecutor
        ) { (_, result: Result<AddIncomingDefaultsResponse, ResponseError>) in
            do {
                let response = try result.get()

                try self.writeToDatabase { context in
                    /*
                     If the local object doesn't exist when this request finished processing, it can mean either of two things:
                     - incoming defaults are being refetched
                     - the user has unblocked the sender in the mean time
                     In both cases, we shouldn't attempt to recreate it here.
                     */

                    if try !self.find(query: .email(emailAddress), in: context, includeSoftDeleted: false).isEmpty {
                        try self.save(dto: response.incomingDefault, in: context)
                    }
                }

                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func delete(query: Query) throws {
        try writeToDatabase { context in
            try self.find(query: query, in: context, includeSoftDeleted: true).forEach(context.delete)
        }
    }
}

// MARK: internals

extension IncomingDefaultService {
    private func writeToDatabase(block: @escaping (NSManagedObjectContext) throws -> Void) throws {
        var result: Result<Void, Error>!

        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            do {
                try block(context)

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

                try self.writeToDatabase { context in
                    for dto in response.incomingDefaults {
                        try self.save(dto: dto, in: context)
                    }
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

    private func find(
        query: Query,
        in context: NSManagedObjectContext,
        includeSoftDeleted: Bool
    ) throws -> [IncomingDefault] {
        let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)

        let userIDPredicate = NSPredicate(
            format: "%K == %@",
            IncomingDefault.Attribute.userID.rawValue,
            dependencies.userInfo.userId
        )

        var subpredicates: [NSPredicate] = [
            userIDPredicate
        ]

        if let queryPredicate = query.predicate {
            subpredicates.append(queryPredicate)
        }

        if !includeSoftDeleted {
            let noSoftDeletedPredicate = NSPredicate(
                format: "%K != %@",
                IncomingDefault.Attribute.isSoftDeleted.rawValue,
                NSNumber(true)
            )
            subpredicates.append(noSoftDeletedPredicate)
        }

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)

        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \IncomingDefault.time, ascending: true)
        ]

        let incomingDefaults = try context.fetch(fetchRequest)

        switch query {
        case .email(let email):
            return incomingDefaults.filter { $0.email == email }
        default:
            return incomingDefaults
        }
    }

    private func save(dto: IncomingDefaultDTO, in context: NSManagedObjectContext) throws {
        if let existingIncomingDefault = try find(
            query: .email(dto.email),
            in: context,
            includeSoftDeleted: false
        ).first {
            let existingObjectIsOlder = existingIncomingDefault.time <= dto.time
            if existingIncomingDefault.id == nil || existingObjectIsOlder {
                context.delete(existingIncomingDefault)
                store(dto: dto, in: context)
            }
        } else {
            store(dto: dto, in: context)
        }
    }

    private func store(dto: IncomingDefaultDTO, in context: NSManagedObjectContext) {
        let incomingDefault = IncomingDefault(context: context)
        incomingDefault.email = dto.email
        incomingDefault.id = dto.id
        incomingDefault.location = "\(dto.location.rawValue)"
        incomingDefault.time = dto.time
        incomingDefault.userID = dependencies.userInfo.userId
    }
}

// MARK: related types

extension IncomingDefaultService {
    struct Dependencies {
        let apiService: APIService
        let contextProvider: CoreDataContextProviderProtocol
        let userInfo: UserInfo
    }

    enum Query {
        case email(String)
        case id(String)
        case location(IncomingDefaultsAPI.Location)

        var predicate: NSPredicate? {
            switch self {
            case .email:
                return nil
            case .id(let id):
                return NSPredicate(
                    format: "%K == %@",
                    IncomingDefault.Attribute.id.rawValue,
                    id
                )
            case .location(let location):
                return NSPredicate(
                    format: "%K == %@",
                    IncomingDefault.Attribute.location.rawValue,
                    "\(location.rawValue)"
                )
            }
        }
    }
}
