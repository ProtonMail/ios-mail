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

// sourcery: mock
protocol SetupCoreDataService {
    func setup() throws
}

/// This class exists to abstract the setup method which causes inconsistencies in tests
/// because of the sharedServices
final class SetupCoreData: SetupCoreDataService {
    typealias Dependencies = AnyObject & HasLastUpdatedStoreProtocol

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func setup() throws {
        do {
            try CoreDataStore.shared.initialize()

            sharedServices.add(CoreDataContextProviderProtocol.self, for: CoreDataService.shared)
            sharedServices.add(CoreDataService.self, for: CoreDataService.shared)
            let lastUpdatedStore = dependencies.lastUpdatedStore
            sharedServices.add(LastUpdatedStore.self, for: lastUpdatedStore)
            sharedServices.add(LastUpdatedStoreProtocol.self, for: lastUpdatedStore)
        } catch {
            PMAssertionFailure(error)
            throw error
        }
    }
}
