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
import PromiseKit
import ProtonCore_TestingToolkit

@testable import ProtonMail

class MockContactProvider: ContactProviderProtocol {
    private let coreDataContextProvider: CoreDataContextProviderProtocol

    private (set) var isFetchContactsCalled = false
    var allEmailsToReturn: [Email] = []
    var allContactsToReturn: [ContactEntity] = []
    private(set) var wasCleanUpCalled: Bool = false

    init(coreDataContextProvider: CoreDataContextProviderProtocol) {
        self.coreDataContextProvider = coreDataContextProvider
    }

    func getContactsByIds(_ ids: [String]) -> [ContactEntity] {
        return allContactsToReturn
    }

    @FuncStub(MockContactProvider.getEmailsByAddress, initialReturn: []) var getEmailsByAddressStub
    func getEmailsByAddress(_ emailAddresses: [String], for userId: UserID) -> [EmailEntity] {
        getEmailsByAddressStub(emailAddresses, userId)
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
