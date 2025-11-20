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

import Contacts

@testable import InboxContacts

class CNContactStoreSpy: CNContactStoring {

    static var stubbedAuthorizationStatus: [CNEntityType: CNAuthorizationStatus] = .default

    private(set) var requestAccessCalls: [(entityType: CNEntityType, completionHandler: (Bool, (any Error)?) -> Void)] = []
    private(set) var enumerateContactsCalls: [CNContactFetchRequest] = []
    var stubbedEnumerateContacts: [CNContact] = []
    var requestAccessCompletionBlockCalledImmediately: Bool = false

    static func cleanUp() {
        stubbedAuthorizationStatus = .default
    }

    // MARK: - CNContactStoring

    class func authorizationStatus(for entityType: CNEntityType) -> CNAuthorizationStatus {
        stubbedAuthorizationStatus[entityType].unsafelyUnwrapped
    }

    func requestAccess(for entityType: CNEntityType, completionHandler: @escaping (Bool, (any Error)?) -> Void) {
        requestAccessCalls.append((entityType, completionHandler))

        if requestAccessCompletionBlockCalledImmediately {
            completionHandler(true, nil)
        }
    }

    func enumerateContacts(
        with fetchRequest: CNContactFetchRequest,
        usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void
    ) throws {
        enumerateContactsCalls.append(fetchRequest)

        let ok = UnsafeMutablePointer<ObjCBool>.init(bitPattern: 1)!
        stubbedEnumerateContacts.forEach { contact in
            block(contact, ok)
        }
    }

}

extension Dictionary where Key == CNEntityType, Value == CNAuthorizationStatus {

    static var `default`: Self {
        [.contacts: .notDetermined]
    }

}
