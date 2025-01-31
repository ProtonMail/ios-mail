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

@testable import InboxContacts
import Contacts
import InboxTesting
import proton_app_uniffi
import XCTest

final class ContactPermissionsHandlerTests: BaseTestCase {
    
    var sut: ContactPermissionsHandler!
    var contactStoreSpy: CNContactStoreSpy!
    
    override func setUp() {
        super.setUp()
        contactStoreSpy = .init()
        sut = .init(permissionsHandler: CNContactStoreSpy.self, contactStore: contactStoreSpy)
    }
    
    override func tearDown() {
        contactStoreSpy = nil
        sut = nil
        CNContactStoreSpy.cleanUp()
        super.tearDown()
    }
    
    func testRequestAccessIfNeeded_WhenPermissionsNotDetermined_ItRequestForPermissions() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .notDetermined]
        
        contactStoreSpy.requestAccessCompletionBlockCalledImmediately = true
        
        let granted = await sut.requestAccessIfNeeded()
        
        XCTAssertEqual(contactStoreSpy.requestAccessCalls.count, 1)
        XCTAssertEqual(contactStoreSpy.requestAccessCalls.last?.entityType, .contacts)
        XCTAssertEqual(granted, true)
    }
    
    func testRequestAccessIfNeeded_WhenPermissionsRestricted_ItDoesNotRequestForPermissions() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .restricted]
        
        let granted = await sut.requestAccessIfNeeded()
        
        XCTAssertEqual(contactStoreSpy.requestAccessCalls.count, 0)
        XCTAssertEqual(granted, false)
    }
    
    func testRequestAccessIfNeeded_WhenPermissionsDenied_ItDoesNotRequestForPermissions() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]
        
        let granted = await sut.requestAccessIfNeeded()
        
        XCTAssertEqual(contactStoreSpy.requestAccessCalls.count, 0)
        XCTAssertEqual(granted, false)
    }

    func testRequestAccessIfNeeded_WhenPermissionsLimited_ItDoesNotRequestForPermissions() async {
        if #available(iOS 18.0, *) {
            CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .limited]
            
            let granted = await sut.requestAccessIfNeeded()
            
            XCTAssertEqual(contactStoreSpy.requestAccessCalls.count, 0)
            XCTAssertEqual(granted, true)
        }
    }
    
    func testRequestAccessIfNeeded_WhenPermissionsAuthorized_ItDoesNotRequestForPermissions() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .authorized]
        
        let granted = await sut.requestAccessIfNeeded()
        
        XCTAssertEqual(contactStoreSpy.requestAccessCalls.count, 0)
        XCTAssertEqual(granted, true)
    }
    
}
