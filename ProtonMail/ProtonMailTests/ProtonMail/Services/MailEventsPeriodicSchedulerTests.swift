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
import ProtonCoreDataModel
import ProtonCoreTestingToolkit
@testable import ProtonMail
import XCTest

final class MailEventsPeriodicSchedulerTests: XCTestCase {
    private var sut: MailEventsPeriodicScheduler!
    private var testContainer: TestContainer!
    private var testUsers: [UserManager] = []
    private var apiMocks: [UserID: APIServiceMock] = [:]
    private var eventIDMap: [UserID: String] = [:]
    private var newEventIDMap: [UserID: String] = [:]

    override func setUp() {
        super.setUp()
        testContainer = .init()
        sut = testContainer.mailEventsPeriodicScheduler
    }

    override func tearDown() {
        super.tearDown()
        sut.reset()
        sut = nil
        testContainer = nil
        testUsers.removeAll()
        apiMocks.removeAll()
        eventIDMap.removeAll()
        newEventIDMap.removeAll()
    }

    func testEnableSpecialLoop_withOneUser_eventApiWillBeTriggered() throws {
        try createTestUser()

        sut.enableSpecialLoop(forSpecialLoopID: testUsers[0].userID.rawValue)
        sut.start()

        waitForExpectations(timeout: 1)
        wait(self.apiMocks[self.testUsers[0].userID]?.requestDecodableStub.wasCalledExactlyOnce == true)
    }

    func testEnableSpecialLoop_withMultipleUser_eventApisWillBeTriggered() throws {
        for _ in 0 ..< 5 {
            try createTestUser()
        }

        for user in testUsers {
            sut.enableSpecialLoop(forSpecialLoopID: user.userID.rawValue)
        }
        sut.start()

        waitForExpectations(timeout: 1)
        for item in apiMocks {
            XCTAssertTrue(item.value.requestDecodableStub.wasCalledExactlyOnce)
        }

        for item in newEventIDMap {
            wait(self.testContainer.lastUpdatedStore.lastEventID(userID: item.key) == item.value)
        }
    }

    func testSpecialLoop_withUserSettingResponse_SettingsWillBeUpdated() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.userSettings)

        XCTAssertEqual(user.userInfo.notificationEmail, "test@pm.me")
        XCTAssertEqual(user.userInfo.notify, 0)
        XCTAssertEqual(user.userInfo.passwordMode, 1)
        XCTAssertEqual(user.userInfo.twoFactor, 0)
        XCTAssertEqual(user.userInfo.weekStart, 0)
        XCTAssertEqual(user.userInfo.telemetry, 0)
        XCTAssertEqual(user.userInfo.crashReports, 1)
        XCTAssertEqual(user.userInfo.referralProgram?.link, "https://pr.tn/ref/xxxx")
        XCTAssertEqual(user.userInfo.referralProgram?.eligible, false)
        XCTAssertEqual(user.userInfo.usedSpace, 553769095)
    }

    func testSpecialLoop_withMailSettingsResponse_SettingsWillBeUpdated() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.mailSettings)

        XCTAssertEqual(user.userInfo.displayName, "TestName")
        XCTAssertEqual(user.userInfo.defaultSignature, "")
        XCTAssertEqual(user.userInfo.hideEmbeddedImages, 1)
        XCTAssertEqual(user.userInfo.hideRemoteImages, 1)
        XCTAssertEqual(user.userInfo.imageProxy, .imageProxy)
        XCTAssertEqual(user.userInfo.autoSaveContact, 0)
        XCTAssertEqual(user.userInfo.swipeLeft, 0)
        XCTAssertEqual(user.userInfo.swipeRight, 4)
        XCTAssertEqual(user.userInfo.linkConfirmation, .confirmationAlert)
        XCTAssertEqual(user.userInfo.attachPublicKey, 0)
        XCTAssertEqual(user.userInfo.sign, 1)
        XCTAssertEqual(user.userInfo.enableFolderColor, 1)
        XCTAssertEqual(user.userInfo.inheritParentFolderColor, 0)
        XCTAssertEqual(user.userInfo.groupingMode, 0)
        XCTAssertEqual(user.userInfo.delaySendSeconds, 10)
        XCTAssertEqual(user.userInfo.conversationToolbarActions, .init(isCustom: false, actions: []))
        XCTAssertEqual(user.userInfo.messageToolbarActions, .init(isCustom: true, actions: ["trash", "toggle_read"]))
        XCTAssertEqual(user.userInfo.listToolbarActions, .init(isCustom: false, actions: []))

        XCTAssertEqual(user.mailSettings.autoDeleteSpamTrashDays, .implicitlyDisabled)
        XCTAssertEqual(user.mailSettings.hideSenderImages, false)
        XCTAssertEqual(user.mailSettings.nextMessageOnMove, .explicitlyDisabled)
        XCTAssertEqual(user.mailSettings.showMoved, .doNotKeep)
        XCTAssertEqual(user.mailSettings.almostAllMail, true)
    }

    func testSpecialLoop_withIncomingDefaultResponse_incomingDefaultWillBeUpdated() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.incomingDefaults) {
            try self.testContainer.contextProvider.write { context in
                let data = IncomingDefault(context: context)
                data.id = "w1NatTSaDDRIXxlRSpY"
                data.location = "14"
                data.email = "delete@proton.me"
                data.time = Date()
                data.userID = self.testUsers.first?.userID.rawValue ?? ""
            }
        }

        let results = try testContainer.contextProvider.performAndWaitOnRootSavingContext() { context in
            let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.Attribute.entityName)
            return (try context.fetch(fetchRequest).map(IncomingDefaultEntity.init)) ?? []
        }

        XCTAssertEqual(results.count, 2)
        let firstResult = try XCTUnwrap(results[safe: 0])
        XCTAssertEqual(firstResult.id, "NuYq04-jVQL6dd4w1NatTSaDDRIXxlRSpYZQq_GeRI0Nsx94GA==")
        XCTAssertEqual(firstResult.location, .blocked)
        XCTAssertEqual(firstResult.email, "test1@proton.me")
        XCTAssertEqual(firstResult.time.timeIntervalSince1970, 1699507315)
        XCTAssertEqual(firstResult.userID, user.userID)

        let secondResult = try XCTUnwrap(results[safe: 1])
        XCTAssertEqual(secondResult.id, "q04-jVQL6dd4w1NatTSaDDRIXxlRSpYZQq_GeR")
        XCTAssertEqual(secondResult.location, .blocked)
        XCTAssertEqual(secondResult.email, "test2@proton.me")
        XCTAssertEqual(secondResult.time.timeIntervalSince1970, 1699507115)
        XCTAssertEqual(secondResult.userID, user.userID)
    }

    func testSpecialLoop_withAddressesResponse_addressesDataWillBeUpdated() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.addresses)

        XCTAssertEqual(user.userInfo.userAddresses.count, 1)
        let address = try XCTUnwrap(user.userInfo.userAddresses.first)
        XCTAssertEqual(address.addressID, "JwUa_eV8uqbTqVNeYtedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==")
        XCTAssertEqual(address.domainID, "pIJGEYyNFsPEb61o2JrcdohiRuWSN2i1rgnkEnZmolVx4Np96IcwxJh1WNw==")
        XCTAssertEqual(address.email, "test@proton.me")
        XCTAssertEqual(address.status, .enabled)
        XCTAssertEqual(address.type, .protonDomain)
        XCTAssertEqual(address.receive, .active)
        XCTAssertEqual(address.send, .active)
        XCTAssertEqual(address.displayName, "L")
        XCTAssertEqual(address.signature, "")
        XCTAssertEqual(address.order, 1)
        XCTAssertEqual(address.hasKeys, 1)
        XCTAssertEqual(address.keys.count, 2)

        let firstKey = try XCTUnwrap(address.keys.first)
        XCTAssertEqual(firstKey.keyID, "4NjM11QwBRhJemHW4jEUA==")
        XCTAssertEqual(firstKey.primary, 1)
        XCTAssertEqual(firstKey.flags.rawValue, 3)
        XCTAssertEqual(firstKey.fingerprint, "5d9a4103fb0fd83f604600bc4bbe389b7494b58d")
        XCTAssertEqual(firstKey.active, 1)
        XCTAssertEqual(firstKey.version, 3)
        XCTAssertEqual(firstKey.activation, nil)
        XCTAssertEqual(firstKey.privateKey, "-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: GopenPGP 2.5.0\nComment: https://gopenpgp.org\n\nxYYEY+8x+hYJKwYBBAHaRw8BAQdAClNY5grIa+9A1yJUB+WEoa1YqHEv9Y9kY2Ye\n9drO7Fj+CQMI/6nqJsFlQyBgm8sfTguiRcyg155wS4f+iYrB8URfrTK04OZVmHFa\nbfbbQvFo9YUwoI0W6V9+KOjh6SSuNt1oTna0eEMkSP2eMop1glGEQM1aM0YzM0Qz\nMTgtMDhCRC00RUY1LTlCMTktMzQxQ0Y0RDYwMzRDIDwzRjMzRDMxOC0wOEJELTRF\nRjUtOUIxOS0zNDFDRjRENjAzNENAcHJvdG9ubWFpbC5jb20+wowEExYIAD4FAmPv\nMfoJkEu+OJt0lLWNFiEEXZpBA/sP2D9gRgC8S744m3SUtY0CGwMCHgECGQEDCwkH\nAhUIAxYAAgIiAQAAHTQBANQuLTT/nojjTm4a9vOUmuJ6gGrXwv3LUXbSdriDfNVN\nAQD+Yz6IV+cdFfrnM2R7Ckb3gzGZHOPibmRyDLYr8ssZDceLBGPvMfoSCisGAQQB\nl1UBBQEBB0Ag1zLHTZs6+ohzsVAPteVac/TABgwyWVuUh9ZCnK5FWAMBCgn+CQMI\nfKQAON4aJw5gUKI70IVWwX1k/jWRnvHcPgyEDstND10njVhKuMX51cciUiB7O7hq\nD+QYf9fbus4qv1wEJxuZaGgaKdH05AyWvqUT7kZQKMJ4BBgWCAAqBQJj7zH6CZBL\nvjibdJS1jRYhBF2aQQP7D9g/YEYAvEu+OJt0lLWNAhsMAACumgEA0RvagIs7Vsvt\n5wceDHrYIASpSP6YEC6pMHVvILHJEh4A/AhQVe7UTHnOFTfq61SB01C5snIF4S9s\n8u81+Jzo408J\n=Yz3C\n-----END PGP PRIVATE KEY BLOCK-----")
        XCTAssertEqual(
            firstKey.token,
            "-----BEGIN PGP MESSAGE-----\nVersion: ProtonMail\n\nwV4D86C6JLhOkfkSAQdA6d/8geU5CFP2HQp7HhR9GI92liXoKMYaC2p0a/hHxCB/+A0lb8kb2Afr4BoC0yJ6uIqs4133dcPWpB+/IX6\n1TRnIg5NDjDEJr4UOC+mJkd5ldEzR35nTtmmxpRFS6Pdlm3aR7o=\n=dReU\n-----END PGP MESSAGE-----\n"
        )
        XCTAssertEqual(
            firstKey.signature,
            "-----BEGIN PGP SIGNATURE-----\nVersion: ProtonMail\n\nwnUEARYKAAYFAmHuZ0kAIQkQMn9fPRge1msWIQT5guksoDFantnTh+Eyf189\nGB7Wa1XViXZ1AA=\n=HPz6\n-----END PGP SIGNATURE-----\n"
        )

        let secondKey = try XCTUnwrap(address.keys.last)
        XCTAssertEqual(secondKey.keyID, "o6MJHyu55uvLrikV6NOp9J7blBHC_C7xwjmiBRWQCL_xEbAazAv0A==")
        XCTAssertEqual(secondKey.primary, 0)
        XCTAssertEqual(secondKey.flags.rawValue, 3)
        XCTAssertEqual(secondKey.fingerprint, "906e82d7262bec9fd7bc9b70440f664b75505bbb")
        XCTAssertEqual(secondKey.active, 1)
        XCTAssertEqual(secondKey.version, 3)
        XCTAssertEqual(secondKey.activation, nil)
        XCTAssertEqual(secondKey.privateKey, "-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: GopenPGP 2.7.3\nComment: https://gopenpgp.org\n\nxYYEZVRNhBYJKwYBBAHaRw8BAQdAdVG+SX8abqKeH2Nywq6EDz3GE5zi3Hs/THh3\nnAsHBqP+CQMIcC9j7f6YZ6VgS+xkRxTfofZT6dlDaTMg2PlRGYWv6IR6YaAs+1tC\nqdFx/O6hWFICE3zc5YZB8Gq4SeGm1DgePICVWJx+D36+8eOgeBkUkc1aNUJDNDBB\nNEYtNDQwNC00QzE3LThEN0UtQzVCRTgwMTQ2MENBIDw1QkM0MEE0Ri00NDA0LTRD\nMTctOEQ3RS1DNUJFODAxNDYwQ0FAcHJvdG9ubWFpbC5jb20+wo8EExYIAEEFAmVU\nTYQJEEQPZkt1UFu7FiEEkG6C1yYr7J/XvJtwRA9mS3VQW7sCGwMCHgECGQEDCwkH\nAhUIAxYAAgUnCQIHAgAAfXkBAIUBM5AIxWF+99NWZfrfX4bjA4g9DvSDW8wkhlKc\nZWSwAQCFUOXEwOG1RW6y61IXXWvopuOASkWPzLquSue3EJqpBceLBGVUTYQSCisG\nAQQBl1UBBQEBB0DiI+hRZPeTzHX5aE+JhKeRH+IapC4aHCqDE7TrwpshMgMBCgn+\nCQMIWju2HIPIONNgxNR6gHcV/qCS7sa8Z4aavx1tP5FYQbYWtawAriJXy8zzo7qk\nvFVvvBAgMNE/5TF7cL1NXAtUmTAOOe21yNhp838uZi311cJ4BBgWCAAqBQJlVE2E\nCRBED2ZLdVBbuxYhBJBugtcmK+yf17ybcEQPZkt1UFu7AhsMAABRtAEAhoMk2q7M\n8ZfGk8UkCpVWVjK92V1uRqbVDiREthP+FW0BAIgMomJF6vzMDwn5WhMOTIemV5nO\nUDIPtEdYomZrP0sA\n=UlWf\n-----END PGP PRIVATE KEY BLOCK-----")
        XCTAssertEqual(secondKey.token, "-----BEGIN PGP MESSAGE-----\nVersion: ProtonMail\n\nwV4DQg7fTNedqRMSAQdAg0LTE0H+evspZxj2+dQ/8CRKMMmJ00Ku7rR4XY6Y7XeBpbO+jGQVQ+XFGx1d2V2klwHzcOrYen9vY\nlFDK58bu1pf6Cuat82fW68N57+P27yrTLZ0nb2ppZS7iNjcPlKU=\n=3s0w\n-----END PGP MESSAGE-----\n")
        XCTAssertEqual(secondKey.signature, "-----BEGIN PGP SIGNATURE-----\nVersion: ProtonMail\n\nwnUEARYKAAYFAmGyvlsAIQkQUBJWQeVkjFUWIQSKTHKRHplL32DXq+xQElZBVmCkpK0HyTpQM=\n=RCV9\n-----END PGP SIGNATURE-----\n")
    }

    func testSpecialLoop_withUserResponse_userWillBeUpdated() throws {
        let userID = "Rbfvlksgs11Q=="
        let user = try prepareEventAPIResponse(from: EventTestData.user, userID: .init(userID))

        XCTAssertEqual(user.userInfo.delinquent, 0)
        XCTAssertEqual(user.userInfo.maxSpace, 1073741824)
        XCTAssertEqual(user.userInfo.maxUpload, 26214400)
        XCTAssertEqual(user.userInfo.role, 0)
        XCTAssertEqual(user.userInfo.subscribed.rawValue, 0)
        XCTAssertEqual(user.userInfo.usedSpace, 553769095)
        XCTAssertEqual(user.userInfo.userId, userID)
        XCTAssertEqual(user.userInfo.userKeys.count, 2)

        let firstKey = try XCTUnwrap(user.userInfo.userKeys.first)
        XCTAssertEqual(firstKey.keyID, "18LqT9H5Rxz2pjYYtIFk_4K8AHU1Wmfh6kAOUcm0XGbSRA==")
        XCTAssertEqual(firstKey.version, 3)
        XCTAssertEqual(firstKey.primary, 1)
        XCTAssertEqual(firstKey.privateKey, "-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: GopenPGP 2.7.3\nComment: https://gopenpgp.org\n\nxYYEZVRT4hYJKwYBBAHaRw8BAQdA5zeaaqDXZHASWQq+dFZ9AhK51DY5QhQw7bpc\nJfKAG8H+CQMIPM5gDwDkswdgA5kOowfjOKfX5KjxyG5npR1OuCe9bxl0cLxoBp0L\nRWCtNbkdU0+tmu2VulKp+JDrNFxsTy+d4ymZObssTq84KmbNL6Y85M1aRjdBNTg3\nODYtMzU2MS00NEQ2LUE0MjktNEMwNEI4OEUyRkNGIDxGN0E1ODc4Ni0zNTYxLTQ0\nRDYtQTQyOS00QzA0Qjg4RTJGQ0ZAcHJvdG9ubWFpbC5jb20+wo8EExYIAEEFAmVU\nU+IJEP1N/9d+WklgFiEE9LaW08SydK5gSDSm/U3/135aSWACGwMCHgECGQEDCwkH\nAhUIAxYAAgUnCQIHAgAAxHkBAKH5SO21v+J/mjAGy4CYdQ7h9FVyEGzeVbPwri2L\nfXM/AP0UCaK3JSHhpUoTkOQYptw8RAk+wpIaSPEKUZitITGwCceLBGVUU+ISCisG\nAQQBl1UBBQEBB0DRCu+Vwb028XTnZouaeXLeshk8ohrn6KX9H9nebjKdOgMBCgn+\nCQMIx+QBI+HjclhgOKcal9ZA5lLC6mLoxwbOaerhR2GZ8UKODp2dVJfCQgDE6lPH\nlnsx38P12bJU/mXTqukh1gLOvvSaZTi9kRjo+SKI9U1n+sJ3BBgWCAAqBQJlVFPi\nCRD9Tf/XflpJYBYhBPS2ltPEsnSuYEg0pv1N/9d+WklgAhsMAABnRgD3ehppTpZO\nLtT4dLzKaouqdt+m0vITFNmigr8tBNyceAEA1nKYMuxHUizpHv1NzNkxFXUN+aJ+\nC+tKzt+POd2kOQc=\n=JaHu\n-----END PGP PRIVATE KEY BLOCK-----")
        XCTAssertEqual(firstKey.fingerprint, "f4b696d3c4b274ae604834a6fd4dffd77e5a4960")
        XCTAssertEqual(firstKey.active, 1)

        let secondKey = try XCTUnwrap(user.userInfo.userKeys.last)
        XCTAssertEqual(secondKey.keyID, "Y0AUSJZReSj1ug==")
        XCTAssertEqual(secondKey.version, 3)
        XCTAssertEqual(secondKey.primary, 0)
        XCTAssertEqual(secondKey.privateKey, "-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: GopenPGP 2.7.3\nComment: https://gopenpgp.org\n\nxYYEZVRUWBYJKwYBBAHaRw8BAQdA37qpqg8LELjaUfQQGFJv9jrnLykT93qUwlKb\nK+Ix0DH+CQMIqeuP+0jT3pVg+lgXF71ibZ0VGwl/HJdp8/vszQBwBb0uLVlkbyRj\neGk/XG+psmttgnsIP26EH/Y5WtUyNWuyu+wLjR2WTWYDM6Y2b46wi81aQzVBMTdB\nREUtRkU3My00MTlCLTlCNkYtMUU1N0Q1RkFGNUNGIDxDNUExN0FERS1GRTczLTQx\nOUItOUI2Ri0xRTU3RDVGQUY1Q0ZAcHJvdG9ubWFpbC5jb20+wo8EExYIAEEFAmVU\nVFgJELATbCHfKMDrFiEEw8H2LFHvwZyAYPZHsBNsId8owOsCGwMCHgECGQEDCwkH\nAhUIAxYAAgUnCQIHAgAAQXQBAOVKu1PCeq3BlxMyv7FMorGyLTdWaIJqqyJKtmZP\nmzTvAQCcsqt3zM8aE0x4t2QOOdMLmYgdC5SnRAbkKmJcSi9xAseLBGVUVFgSCisG\nAQQBl1UBBQEBB0AIURdvuUsKE4yR81DUQuiKzTSHGRQ/JNgbWGQZ+RJwUAMBCgn+\nCQMIfYaA9O3CgNFgBqE2rBi0PV6iOnYVnbfuQs2/NOWc7MnyLz2z4dN39qkOlUN0\nJ9vplE0/ZM0jZQCczgirQKMsEn83/vSEg91kRtVm5vUK2MJ4BBgWCAAqBQJlVFRY\nCRCwE2wh3yjA6xYhBMPB9ixR78GcgGD2R7ATbCHfKMDrAhsMAADYhQD/Q6mljhO+\nLJrfnsBoT5faMC+gA1gj5ZAHk+vuDH8GCx0BAKOSr/8OrVWCDfGSrQVpZZSu3Lrp\nYJr0orR/xSWxZaIH\n=3eAH\n-----END PGP PRIVATE KEY BLOCK-----")
        XCTAssertEqual(secondKey.fingerprint, "c3c1f62c51efc19c8060f647b0136c21df28c0eb")
        XCTAssertEqual(secondKey.active, 1)
    }

    func testSpecialLoop_withMessageCountResponse_dataWillBeUpdatedInCache() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.messageCounts)

        let lastUpdatedStore = testContainer.lastUpdatedStore
        let labelIDs: [LabelID] = ["0", "1", "2", "3", "4", "5", "15", "6", "7", "8", "9", "12", "10", "16", "_CnYJz7oOv1GTZ0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH84pvqQ6g86W-0Qd5o1Vk0x8WTOKq6g==", "Y7WZniLsZpKoozhCudxqGJJNWYAmFpzvfK9phOmApaUP1TJOoocri2IN7q9ljTR8_wAzB6GshCeb10_MCOq67A==", "y4979YHYB6C0Cc11RV84TociphRjY8EYHAHBmPvcYYoZ-goDI5bn8OtxZgTr58svKsijwMrG7qjnokpfykfqYQ==", "PYW3f9DGHAExMdOQMbmKN5lIDaUCu652_3BptaOWyOMWhFGvxgX9EOLW4G8kuvWFedDKFoTWpIuePVav1Vr21Q=="]
        let results = lastUpdatedStore.getUnreadCounts(by: labelIDs, userID: user.userID, type: .singleMessage)

        XCTAssertEqual(
            results["0"],
            56
        )
        XCTAssertEqual(
            results["1"],
            0
        )
        XCTAssertEqual(
            results["2"],
            0
        )
        XCTAssertEqual(
            results["3"],
            0
        )
        XCTAssertEqual(
            results["4"],
            0
        )
        XCTAssertEqual(
            results["5"],
            56
        )
        XCTAssertEqual(
            results["15"],
            56
        )
        XCTAssertEqual(
            results["6"],
            0
        )
        XCTAssertEqual(
            results["7"],
            0
        )
        XCTAssertEqual(
            results["8"],
            0
        )
        XCTAssertEqual(
            results["9"],
            0
        )
        XCTAssertEqual(
            results["10"],
            0
        )
        XCTAssertEqual(
            results["12"],
            0
        )
        XCTAssertEqual(
            results["16"],
            0
        )
        XCTAssertEqual(
            results["_CnYJz7oOv1GTZ0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH84pvqQ6g86W-0Qd5o1Vk0x8WTOKq6g=="],
            9
        )
        XCTAssertEqual(
            results["Y7WZniLsZpKoozhCudxqGJJNWYAmFpzvfK9phOmApaUP1TJOoocri2IN7q9ljTR8_wAzB6GshCeb10_MCOq67A=="],
            0
        )
        XCTAssertEqual(
            results["y4979YHYB6C0Cc11RV84TociphRjY8EYHAHBmPvcYYoZ-goDI5bn8OtxZgTr58svKsijwMrG7qjnokpfykfqYQ=="],
            0
        )
        XCTAssertEqual(
            results["PYW3f9DGHAExMdOQMbmKN5lIDaUCu652_3BptaOWyOMWhFGvxgX9EOLW4G8kuvWFedDKFoTWpIuePVav1Vr21Q=="],
            0
        )
    }

    func testSpecialLoop_withConversationCountResponse_dataWillBeUpdatedInCache() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.conversationCounts)

        let lastUpdatedStore = testContainer.lastUpdatedStore
        let labelIDs: [LabelID] = ["0", "1", "2", "3", "4", "5", "15", "6", "7", "8", "9", "12", "10", "16", "_CnYJz7oOv1GTZ0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH84pvqQ6g86W-0Qd5o1Vk0x8WTOKq6g==", "Y7WZniLsZpKoozhCudxqGJJNWYAmFpzvfK9phOmApaUP1TJOoocri2IN7q9ljTR8_wAzB6GshCeb10_MCOq67A==", "y4979YHYB6C0Cc11RV84TociphRjY8EYHAHBmPvcYYoZ-goDI5bn8OtxZgTr58svKsijwMrG7qjnokpfykfqYQ==", "PYW3f9DGHAExMdOQMbmKN5lIDaUCu652_3BptaOWyOMWhFGvxgX9EOLW4G8kuvWFedDKFoTWpIuePVav1Vr21Q=="]
        let results = lastUpdatedStore.getUnreadCounts(by: labelIDs, userID: user.userID, type: .conversation)

        XCTAssertEqual(
            results["0"],
            56
        )
        XCTAssertEqual(
            results["1"],
            0
        )
        XCTAssertEqual(
            results["2"],
            0
        )
        XCTAssertEqual(
            results["3"],
            0
        )
        XCTAssertEqual(
            results["4"],
            0
        )
        XCTAssertEqual(
            results["5"],
            56
        )
        XCTAssertEqual(
            results["15"],
            56
        )
        XCTAssertEqual(
            results["6"],
            0
        )
        XCTAssertEqual(
            results["7"],
            0
        )
        XCTAssertEqual(
            results["8"],
            0
        )
        XCTAssertEqual(
            results["9"],
            0
        )
        XCTAssertEqual(
            results["10"],
            0
        )
        XCTAssertEqual(
            results["12"],
            0
        )
        XCTAssertEqual(
            results["16"],
            0
        )
        XCTAssertEqual(
            results["_CnYJz7oOv1GTZ0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH84pvqQ6g86W-0Qd5o1Vk0x8WTOKq6g=="],
            9
        )
        XCTAssertEqual(
            results["Y7WZniLsZpKoozhCudxqGJJNWYAmFpzvfK9phOmApaUP1TJOoocri2IN7q9ljTR8_wAzB6GshCeb10_MCOq67A=="],
            0
        )
        XCTAssertEqual(
            results["y4979YHYB6C0Cc11RV84TociphRjY8EYHAHBmPvcYYoZ-goDI5bn8OtxZgTr58svKsijwMrG7qjnokpfykfqYQ=="],
            0
        )
        XCTAssertEqual(
            results["PYW3f9DGHAExMdOQMbmKN5lIDaUCu652_3BptaOWyOMWhFGvxgX9EOLW4G8kuvWFedDKFoTWpIuePVav1Vr21Q=="],
            0
        )
    }

    func testSpecialLoop_withContactDeleteResponse_dataWillBeDeletedInCache() throws {
        _ = try prepareEventAPIResponse(from: EventTestData.deleteContact) {
            try? self.testContainer.contextProvider.write(block: { context in
                let contact = Contact(context: context)
                contact.contactID = "XVoMXk6t55XPh-OFw9lM3yLQKYxsuaA5-bN8RzyZKe3ym85iwwVVqZXyQ=="
                contact.userID = self.testUsers.first?.userID.rawValue ?? ""
                let email = Email(context: context)
                email.emailID = "PybPhCZN7O5CEkxPCpJHX_5Dz-aF6HUQsP5E-OEfWST0gcCayq_lYehI8tZckqnCA=="
                email.userID = self.testUsers.first?.userID.rawValue ?? ""
                email.contactID = "XVoMXk6t55XPh-OFw9lM3yLQKYxsuaA5-bN8RzyZKe3ym85iwwVVqZXyQ=="
                email.contact = contact
            })
        }

        let contact = testContainer.contextProvider.read { context in
            Contact.contactForContactID("XVoMXk6t55XPh-OFw9lM3yLQKYxsuaA5-bN8RzyZKe3ym85iwwVVqZXyQ==", inManagedObjectContext: context)
        }
        XCTAssertNil(contact)

        let email = testContainer.contextProvider.read { context in
            Email.emailForID("PybPhCZN7O5CEkxPCpJHX_5Dz-aF6HUQsP5E-OEfWST0gcCayq_lYehI8tZckqnCA==", inManagedObjectContext: context)
        }
        XCTAssertNil(email)
    }

    func testSpecialLoop_withContactEditResponse_dataWillBeUpdatedInCache() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.modifyContact) {
            try? self.testContainer.contextProvider.write { context in
                let emailToBeDeleted = Email(context: context)
                emailToBeDeleted.emailID = "saPUe0mny7kXL44_x8cbJZhBtUtEprh0Qvzb4kO28Ey-vM-R2gwxQ9KbGeLbIPMT2JQxQ=="
                emailToBeDeleted.userID = self.testUsers.first?.userID.rawValue ?? ""
                let emailToBeUpdated = Email(context: context)
                emailToBeUpdated.emailID = "JXpWbUF0BTvKCm56eKQ=="
                emailToBeUpdated.userID = self.testUsers.first?.userID.rawValue ?? ""
            }
        }

        let contact = try XCTUnwrap(
            testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
                Contact.contactForContactID("upBasrP-iFNnomTyeuXVw3n9-4uKoiATZbPPWaQ6F5D70oXIA==", inManagedObjectContext: context)
            }
        )
        XCTAssertEqual(contact.contactID, "upBasrP-iFNnomTyeuXVw3n9-4uKoiATZbPPWaQ6F5D70oXIA==")
        XCTAssertEqual(contact.name, "TestName")
        XCTAssertEqual(contact.uuid, "F57C8277-585D-4327-88A6-B5689FF69DFE")
        XCTAssertEqual(contact.size.intValue, 541)
        XCTAssertEqual(contact.createTime?.timeIntervalSince1970, 1696573579)
        XCTAssertEqual(contact.modifyTIme?.timeIntervalSince1970, 1699593228)
        XCTAssertFalse(contact.cardData.isEmpty)
        XCTAssertEqual(contact.emails.count, 1)

        let email = try XCTUnwrap(Array(contact.emails).first as? Email)
        XCTAssertEqual(email.emailID, "QfgmzQv9W8FyoeCKBaJXpWbUF0BTvKCm56eKQ==")
        XCTAssertEqual(email.name, "Anna Haro")
        XCTAssertEqual(email.email, "anna-haro@mac.com")
        XCTAssertEqual(email.type, "[\"internet\",\"home\",\"pref\"]")
        XCTAssertEqual(email.defaults.intValue, 1)
        XCTAssertEqual(email.order.intValue, 1)
        XCTAssertEqual(email.lastUsedTime?.timeIntervalSince1970, 0)
        XCTAssertEqual(email.contactID, "upBasrP-iFNnomTyeuXVw3n9-4uKoiATZbPPWaQ6F5D70oXIA==")
        XCTAssertEqual(email.labels.count, 0)

        XCTAssertNil(
            try? testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
                Email.emailFor(
                    emailID: "saPUe0mny7kXL44_x8cbJZhBtUtEprh0Qvzb4kO28Ey-vM-R2gwxQ9KbGeLbIPMT2JQxQ==",
                    userID: user.userID,
                    in: context
                )
            }
        )

        let emailToBeUpdated = try XCTUnwrap(
            testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
                Email.emailFor(
                    emailID: "JXpWbUF0BTvKCm56eKQ==",
                    userID: user.userID,
                    in: context
                )
            }
        )
        XCTAssertEqual(emailToBeUpdated.emailID, "JXpWbUF0BTvKCm56eKQ==")
        XCTAssertEqual(emailToBeUpdated.name, "TestName")
        XCTAssertEqual(emailToBeUpdated.email, "testName@proton.me")
        XCTAssertEqual(emailToBeUpdated.type, "[\"internet\",\"home\",\"pref\"]")
        XCTAssertEqual(emailToBeUpdated.defaults.intValue, 0)
        XCTAssertEqual(emailToBeUpdated.order.intValue, 2)
        XCTAssertEqual(emailToBeUpdated.lastUsedTime?.timeIntervalSince1970, 0)
        XCTAssertEqual(emailToBeUpdated.contactID, "iFNnomTyeuXVw3n9")
        XCTAssertEqual(emailToBeUpdated.labels.count, 0)
    }

    func testSpecialLoop_withLabelDeleteResponse_dataWillBeDeletedInCache() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.deleteLabel) {
            try? self.testContainer.contextProvider.write { context in
                let labelToBeDeleted = Label(context: context)
                labelToBeDeleted.labelID = "e7vaVmdmUi4dVUPEGeEoC65PXv-qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA=="
                labelToBeDeleted.userID = self.testUsers.first?.userID.rawValue ?? ""
            }
        }

        let label = testContainer.contextProvider.read { context in
            Label.labelFor(labelID: "e7vaVmdmUi4dVUPEGeEoC65PXv-qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==", userID: user.userID, in: context)
        }
        XCTAssertNil(label)
    }

    func testSpecialLoop_withLabelUpdateResponse_dataWillBeUpdatedInCache() throws {
        let user = try prepareEventAPIResponse(from: EventTestData.newLabel) {
            try? self.testContainer.contextProvider.write { context in
                let labelToBeDeleted = Label(context: context)
                labelToBeDeleted.labelID = "qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA=="
                labelToBeDeleted.userID = self.testUsers.first?.userID.rawValue ?? ""
            }
        }

        let labelToBeAdded = try XCTUnwrap(
            testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
                Label.labelFor(labelID: "e7vaVmdmUi4dVUP5PXv-qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==", userID: user.userID, in: context)
            }
        )
        XCTAssertEqual(labelToBeAdded.labelID, "e7vaVmdmUi4dVUP5PXv-qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==")
        XCTAssertEqual(labelToBeAdded.name, "testLabel")
        XCTAssertEqual(labelToBeAdded.path, "testLabel")
        XCTAssertEqual(labelToBeAdded.type.intValue, 1)
        XCTAssertEqual(labelToBeAdded.color, "#c44800")
        XCTAssertEqual(labelToBeAdded.order.intValue, 14)
        XCTAssertEqual(labelToBeAdded.notify.intValue, 0)
        XCTAssertEqual(labelToBeAdded.sticky.intValue, 0)
        XCTAssertEqual(labelToBeAdded.parentID, "Y8EYHAHBmPvcYYoZ-goDI5bn8Ot")


        let labelToBeUpdated = try XCTUnwrap(
            testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
                Label.labelFor(labelID: "qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==", userID: user.userID, in: context)
            }
        )
        XCTAssertEqual(labelToBeUpdated.labelID, "qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==")
        XCTAssertEqual(labelToBeUpdated.name, "testLabel2")
        XCTAssertEqual(labelToBeUpdated.path, "testLabel2")
        XCTAssertEqual(labelToBeUpdated.type.intValue, 1)
        XCTAssertEqual(labelToBeUpdated.color, "#c44800")
        XCTAssertEqual(labelToBeUpdated.order.intValue, 15)
        XCTAssertEqual(labelToBeUpdated.notify.intValue, 1)
        XCTAssertEqual(labelToBeUpdated.sticky.intValue, 1)
        XCTAssertEqual(labelToBeUpdated.parentID, "")
    }
}

private extension MailEventsPeriodicSchedulerTests {
    private func prepareEventAPIResponse(
        from data: String,
        userID: UserID? = nil,
        insertTestData: (() throws -> Void)? = nil
    ) throws -> UserManager {
        let data = try XCTUnwrap(data.data(using: .utf8))
        let response = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        try createTestUser(response: response, userID: userID)
        let user = try XCTUnwrap(testUsers.first)

        try insertTestData?()

        sut.enableSpecialLoop(forSpecialLoopID: user.userID.rawValue)
        sut.start()
        waitForExpectations(timeout: 1)
        wait(self.apiMocks[user.userID]?.requestDecodableStub.wasCalledExactlyOnce == true)
        wait(user.container.eventProcessor.completeClosureCalledCount == 1)
        return user
    }

    private func createTestUser(response: EventAPIResponse? = nil, userID: UserID? = nil) throws {
        let api = APIServiceMock()
        let user = try UserManager.prepareUser(
            apiMock: api,
            userID: userID ?? .init(String.randomString(10)),
            globalContainer: testContainer
        )
        testUsers.append(user)
        testContainer.usersManager.add(newUser: user)

        let eventID = String.randomString(20)
        eventIDMap[user.userID] = eventID
        apiMocks[user.userID] = api
        testContainer.lastUpdatedStore.updateEventID(by: user.userID, eventID: eventID)
        wait(self.testContainer.lastUpdatedStore.lastEventID(userID: user.userID) == eventID)

        let newEventID = String.randomString(20)
        newEventIDMap[user.userID] = newEventID
        let e = expectation(description: "Closure is called")
        api.requestDecodableStub.bodyIs { _, method, path, _, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(path, "/core/v4/events/\(eventID)?ConversationCounts=1&MessageCounts=1")
            XCTAssertEqual(method, .get)
            let response = response ?? EventAPIResponse(
                code: 2000,
                eventID: newEventID,
                refresh: 0,
                more: 0,
                userSettings: nil,
                mailSettings: nil,
                usedSpace: nil,
                incomingDefaults: nil,
                user: nil,
                addresses: nil,
                messageCounts: nil,
                conversationCounts: nil,
                labels: nil,
                contacts: nil,
                contactEmails: nil,
                conversations: nil,
                messages: nil
            )
            completion(nil, .success(response))
            e.fulfill()
        }
    }
}
