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

@testable import ProtonMail
import XCTest

final class AutoImportStrategyTests: XCTestCase {
    private var sut: AutoImportStrategy!

    override func setUp() {
        super.setUp()
        sut = AutoImportStrategy()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    // MARK: Name

    func testMergeName_whenEqual_itShouldReturnNoChanges() {
        let testName = ContactField.Name(firstName: "Daniel", lastName: "Higgins")
        let result = sut.mergeName(device: testName, proton: testName)
        XCTAssertTrue(result.isNoChange)
    }

    func testMergeName_whenDifferent_itShouldReturnTheDeviceName() {
        let deviceName = ContactField.Name(firstName: "Michael", lastName: "Higgins")
        let protonName = ContactField.Name(firstName: "Mike", lastName: "Higgins")
        let result = sut.mergeName(device: deviceName, proton: protonName)
        XCTAssertEqual(result.value, deviceName)
    }

    // MARK: Formatted Name

    func testMergeFormattedName_whenEqual_itShouldReturnNoChanges() {
        let testName = "Frank Smith"
        let result = sut.mergeFormattedName(device: testName, proton: testName)
        XCTAssertTrue(result.isNoChange)
    }

    func testMergeFormattedName_whenDifferent_itShouldReturnTheDeviceName() {
        let deviceName = "Michael Higgins"
        let protonName = "Mike Higgins"
        let result = sut.mergeFormattedName(device: deviceName, proton: protonName)
        XCTAssertEqual(result.value, deviceName)
    }

    // MARK: Emails

    func testMergeEmails_whenEqual_itShouldReturnNoChanges() {
        let testEmails = [ContactField.Email(type: .home, emailAddress: "a@example.com", vCardGroup: "ITEM9")]
        let result = sut.mergeEmails(device: testEmails, proton: testEmails)
        XCTAssertTrue(result.isNoChange)
    }

    func testMergeEmails_whenAddressMatch_itOverridesProtonTypeKeepingItemsOrder() {
        let deviceEmails = [ContactField.Email(type: .work, emailAddress: "a@example.com", vCardGroup: "whatever")]
        let protonEmails = [
            ContactField.Email(type: .home, emailAddress: "a@example.com", vCardGroup: "item9"),
            ContactField.Email(type: .email, emailAddress: "b@example.com", vCardGroup: "item2")
        ]
        let result = sut.mergeEmails(device: deviceEmails, proton: protonEmails)
        XCTAssertEqual(
            result.value,
            [
                ContactField.Email(type: .work, emailAddress: "a@example.com", vCardGroup: "item9"),
                ContactField.Email(type: .email, emailAddress: "b@example.com", vCardGroup: "item2")
            ]
        )
    }

    func testMergeEmails_whenAddressDoesNotMatch_itAddsTheDeviceEmailAfterAnyProtonDeviceEmail() {
        let deviceEmails = [ContactField.Email(type: .work, emailAddress: "a@example.com", vCardGroup: "item2")]
        let protonEmails = [ContactField.Email(type: .home, emailAddress: "b@example.com", vCardGroup: "item1")]
        let result = sut.mergeEmails(device: deviceEmails, proton: protonEmails)
        XCTAssertEqual(result.value, [protonEmails, deviceEmails].flatMap { $0 })
    }

    func testMergeEmails_whenVCardGroupClashes_itChangesTheOneFromTheDevice() {
        let deviceEmails = [ContactField.Email(type: .work, emailAddress: "a@example.com", vCardGroup: "item3")]
        let protonEmails = [ContactField.Email(type: .home, emailAddress: "b@example.com", vCardGroup: "item3")]
        let result = sut.mergeEmails(device: deviceEmails, proton: protonEmails)
        let originProton = result.value![0]
        XCTAssertEqual(originProton.emailAddress, "b@example.com")
        XCTAssertEqual(originProton.vCardGroup, "item3")
        let originDevice = result.value![1]
        XCTAssertEqual(originDevice.emailAddress, "a@example.com")
        XCTAssertEqual(originDevice.vCardGroup, "item4")
    }

    func testMergeEmails_whenEmailDoesNotExistInDevice_itDoesNotDeleteItFromProton() {
        let deviceEmails = [ContactField.Email]()
        let protonEmails = [ContactField.Email(type: .home, emailAddress: "a@example.com", vCardGroup: "item9")]
        let result = sut.mergeEmails(device: deviceEmails, proton: protonEmails)
        XCTAssertTrue(result.isNoChange)
    }

    func testMergeEmails_whenEmailsIsAdded_andVCardGroupIsMissing_itAddsTheVCardGroup() {
        let deviceEmails = [ContactField.Email(type: .work, emailAddress: "a@example.com", vCardGroup: "")]
        let protonEmails = [
            ContactField.Email(type: .home, emailAddress: "b@example.com", vCardGroup: "item1"),
            ContactField.Email(type: .home, emailAddress: "c@example.com", vCardGroup: "item0")
        ]
        let result = sut.mergeEmails(device: deviceEmails, proton: protonEmails)

        let allGroups = Set(result.value!.map { $0.vCardGroup.lowercased() })
        XCTAssertEqual(allGroups, Set(["item0", "item1", "item2"]))
    }

    // MARK: Addresses

    func testMergeAddresses_whenEqual_itShouldReturnNoChanges() {
        let testAddresses = [
            ContactField.Address(
                type: .home,
                street: "Bailen 42",
                streetTwo: "bajo",
                locality: "Barcelona",
                region: "Catalonia",
                postalCode: "08080",
                country: "Spain",
                poBox: ""
            ),
            ContactField.Address(
                type: .home,
                street: "Lothian Road 392",
                streetTwo: "",
                locality: "Edinburgh",
                region: "Scotland",
                postalCode: "E25D3",
                country: "UK",
                poBox: ""
            )
        ]
        let result = sut.mergeAddresses(device: testAddresses, proton: testAddresses)
        XCTAssertTrue(result.isNoChange)
    }

    func testMergeAddresses_whenNoExactMatchForADeviceAddress_itShouldAddItAsNewAddressAfterAnyProtonAddress() {
        let street = "Bailen 42"
        let streetTwo = "bajo"
        let locality = "Barcelona"
        let region = "Catalonia"
        let postalCode = "08080"
        let country = "Spain"
        let poBox = ""

        let deviceAddresses = [
            ContactField.Address(
                type: .home,
                street: street,
                streetTwo: streetTwo,
                locality: locality,
                region: region,
                postalCode: postalCode,
                country: country,
                poBox: poBox
            )
        ]

        let protonAddresses = [
            ContactField.Address(
                type: .home,
                street: street + ".",
                streetTwo: streetTwo,
                locality: locality,
                region: region,
                postalCode: postalCode,
                country: country,
                poBox: poBox
            )
        ]

        let result = sut.mergeAddresses(device: deviceAddresses, proton: protonAddresses)
        XCTAssertEqual(result.value, [protonAddresses, deviceAddresses].flatMap { $0 })
    }

    // MARK: Phone Numbers

    func testMergePhoneNumbers_whenEqual_itShouldReturnNoChanges() {
        let testPhoneNumbers = [ContactField.PhoneNumber(type: .work, number: "(408) 555-3514")]
        let result = sut.mergePhoneNumbers(device: testPhoneNumbers, proton: testPhoneNumbers)
        XCTAssertTrue(result.isNoChange)
    }

    func testMergePhoneNumbers_whenNumberMatch_itOverridesProtonTypeKeepingItemsOrder() {
        let devicePhoneNumbers = [ContactField.PhoneNumber(type: .work, number: "555-478-7672")]
        let protonPhoneNumbers = [
            ContactField.PhoneNumber(type: .home, number: "(408) 555-3514"),
            ContactField.PhoneNumber(type: .fax, number: "555-478-7672")
        ]
        let result = sut.mergePhoneNumbers(device: devicePhoneNumbers, proton: protonPhoneNumbers)
        XCTAssertEqual(
            result.value,
            [
                ContactField.PhoneNumber(type: .home, number: "(408) 555-3514"),
                ContactField.PhoneNumber(type: .work, number: "555-478-7672")
            ]
        )
    }

    func testMergePhoneNumbers_whenNumberDoesNotMatch_itAddTheDeviceNumberAfterAnyProtonNumber() {
        let devicePhoneNumbers = [ContactField.PhoneNumber(type: .work, number: "540-788-1232")]
        let protonPhoneNumbers = [
            ContactField.PhoneNumber(type: .home, number: "(408) 555-3514"),
            ContactField.PhoneNumber(type: .fax, number: "555-478-7672")
        ]
        let result = sut.mergePhoneNumbers(device: devicePhoneNumbers, proton: protonPhoneNumbers)
        XCTAssertEqual(result.value, [protonPhoneNumbers, devicePhoneNumbers].flatMap { $0 })
    }

    // MARK: Urls

    func testMergeUrls_whenEqual_itShouldReturnNoChanges() {
        let testUrls = [ContactField.Url(type: .custom("shop"), url: "www.proton.me/shop")]
        let result = sut.mergeUrls(device: testUrls, proton: testUrls)
        XCTAssertTrue(result.isNoChange)
    }

    func testMergeUrls_whenDoesNotMatch_itShouldReturnNoChanges() {
        let deviceUrls = [ContactField.Url(type: .work, url: "www.proton.me")]
        let result = sut.mergeUrls(device: deviceUrls, proton: [])
        XCTAssertEqual(result.value, deviceUrls)
    }

    // MARK: Other Info

    func testMergeOtherInfo_whenEqual_itShouldReturnNoChanges() {
        let testBirthday = ContactField.OtherInfo(type: .birthday, value: "1998-01-20")
        let result = sut.mergeOtherInfo(device: testBirthday, proton: testBirthday)
        XCTAssertTrue(result.isNoChange)
    }

    func testMergeOtherInfo_whenDoesNotMatch_itShouldReturnTheDeviceInfo() {
        let deviceOrganization = ContactField.OtherInfo(type: .organization, value: "Proton A.G.")
        let protonOrganization = ContactField.OtherInfo(type: .organization, value: "Proton")
        let result = sut.mergeOtherInfo(device: deviceOrganization, proton: protonOrganization)
        XCTAssertEqual(result.value, deviceOrganization)
    }
}

private extension FieldMergeResult {

    var isNoChange: Bool {
        switch self {
        case .noChange: true
        case .merge: false
        }
    }

    var value: T? {
        switch self {
        case .noChange: nil
        case .merge(let result): result
        }
    }
}
