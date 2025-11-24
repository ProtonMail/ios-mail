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
import InboxTesting
import Testing
import proton_app_uniffi

@testable import InboxContacts

final class ContactPermissionsHandlerTests {
    var sut: ContactPermissionsHandler!
    var contactStoreSpy: CNContactStoreSpy!

    init() {
        contactStoreSpy = .init()
        sut = .init(permissionsHandler: CNContactStoreSpy.self, contactStore: contactStoreSpy)
    }

    deinit {
        CNContactStoreSpy.cleanUp()
    }

    @Test
    func requestAccessIfNeeded_WhenPermissionsNotDetermined_ItRequestForPermissions() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .notDetermined]

        contactStoreSpy.requestAccessCompletionBlockCalledImmediately = true

        let granted = await sut.requestAccessIfNeeded()

        #expect(contactStoreSpy.requestAccessCalls.count == 1)
        #expect(contactStoreSpy.requestAccessCalls.last?.entityType == .contacts)
        #expect(granted == true)
    }

    @Test
    func requestAccessIfNeeded_WhenPermissionsRestricted_ItDoesNotRequestForPermissions() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .restricted]

        let granted = await sut.requestAccessIfNeeded()

        #expect(contactStoreSpy.requestAccessCalls.count == 0)
        #expect(granted == false)
    }

    @Test
    func requestAccessIfNeeded_WhenPermissionsDenied_ItDoesNotRequestForPermissions() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]

        let granted = await sut.requestAccessIfNeeded()

        #expect(contactStoreSpy.requestAccessCalls.count == 0)
        #expect(granted == false)
    }

    @Test
    func requestAccessIfNeeded_WhenPermissionsLimited_ItDoesNotRequestForPermissions() async {
        if #available(iOS 18.0, *) {
            CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .limited]

            let granted = await sut.requestAccessIfNeeded()

            #expect(contactStoreSpy.requestAccessCalls.count == 0)
            #expect(granted == true)
        }
    }

    @Test
    func requestAccessIfNeeded_WhenPermissionsAuthorized_ItDoesNotRequestForPermissions() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .authorized]

        let granted = await sut.requestAccessIfNeeded()

        #expect(contactStoreSpy.requestAccessCalls.count == 0)
        #expect(granted == true)
    }
}
