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
import PromiseKit

@testable import ProtonMail
import PromiseKit

class MockContactProvider: ContactProviderProtocol {
    private (set) var isFetchContactsCalled = false
    var allEmailsToReturn: [Email] = []
    private(set) var wasCleanUpCalled: Bool = false
    var stubbedFetchResult: Swift.Result<[PreContact], Error> = .success([])

    func fetch(byEmails emails: [String], context: NSManagedObjectContext? = nil) -> Promise<[PreContact]> {
        return Promise { seal in
            switch self.stubbedFetchResult {
            case .success(let stubbedContacts):
                let matchingContacts = stubbedContacts.filter { emails.contains($0.email) }
                seal.fulfill(matchingContacts)
            case .failure(let error):
                seal.reject(error)
            }
        }
    }

    func getAllEmails() -> [Email] {
        return allEmailsToReturn
    }

    func fetchContacts(completion: ContactFetchComplete?) {
        isFetchContactsCalled = true
        completion?([], nil)
    }

    func cleanUp() -> Promise<Void> {
        wasCleanUpCalled = true
        return Promise<Void>()
    }
}
