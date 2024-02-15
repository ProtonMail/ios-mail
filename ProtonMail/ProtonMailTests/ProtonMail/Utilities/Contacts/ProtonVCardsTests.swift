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

import XCTest
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreCrypto
@testable import ProtonMail

final class ProtonVCardsTests: XCTestCase {
    private var sut: ProtonVCards!

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    // MARK: read succeeds

    func testRead_whenCardIsSigned_andCorrectKeyIsPassed_itShouldNotThrow() throws {
        sut = ProtonVCards(
            cards: [testSignedCardData],
            userKeys: [testCorrectArmoredKey],
            mailboxPassphrase: testCorrectPassphrase1
        )
        XCTAssertNoThrow(try sut.read())
    }

    func testRead_whenCardIsSignedAndEncrypted_andCorrectKeyIsPassed_itShouldNotThrow() throws {
        sut = ProtonVCards(
            cards: [testSignedAndEncryptedCardData],
            userKeys: [testCorrectArmoredKey],
            mailboxPassphrase: testCorrectPassphrase1
        )
        XCTAssertNoThrow(try sut.read())
    }

    // MARK: read throws

    func testRead_whenThereAreDuplicatedCardDataTypes_itShouldThrow() throws {
        sut = ProtonVCards(
            cards: [testSignedCardData, testSignedCardData],
            userKeys: [testCorrectArmoredKey],
            mailboxPassphrase: testCorrectPassphrase1
        )
        XCTAssertThrowsError(try sut.read())
    }

    func testRead_whenCardIsSigned_andIncorrectKeyIsPassed_itShouldThrow() throws {
        sut = ProtonVCards(
            cards: [testSignedCardData],
            userKeys: [testIncorrectArmoredKey],
            mailboxPassphrase: testCorrectPassphrase1
        )
        XCTAssertThrowsError(try sut.read())
    }

    func testRead_whenCardIsSigned_andIncorrectPassphraseIsPassed_itShouldThrow() throws {
        sut = ProtonVCards(
            cards: [testSignedCardData],
            userKeys: [testCorrectArmoredKey],
            mailboxPassphrase: testIncorrectPassphrase
        )
        XCTAssertThrowsError(try sut.read())
    }

    func testRead_whenCardIsSignedAndEncrypted_andIncorrectKeyIsPassed_itShouldThrow() throws {
        sut = ProtonVCards(
            cards: [testSignedAndEncryptedCardData],
            userKeys: [testIncorrectArmoredKey],
            mailboxPassphrase: testCorrectPassphrase1
        )
        XCTAssertThrowsError(try sut.read())
    }

    func testRead_whenCardIsSignedAndEncrypted_andIncorrectPassphraseIsPassed_itShouldThrow() throws {
        sut = ProtonVCards(
            cards: [testSignedAndEncryptedCardData],
            userKeys: [testCorrectArmoredKey],
            mailboxPassphrase: testIncorrectPassphrase
        )
        XCTAssertThrowsError(try sut.read())
    }

    // MARK: calling attribute functions

    func testName_itShouldReturnTheCorrectData() throws {
        sut = ProtonVCards(
            cards: [testSignedAndEncryptedCardData],
            userKeys: [testCorrectArmoredKey],
            mailboxPassphrase: testCorrectPassphrase1
        )
        try sut.read()

        let name = sut.name()
        XCTAssertEqual(name.firstName, "John")
        XCTAssertEqual(name.lastName, "Appleseed")
    }

    func testFormattedName_itShouldReturnTheCorrectData() throws {
        sut = makeReaderWithMultipleCards()
        try sut.read()

        XCTAssertEqual(sut.formattedName(), "John Appleseed")
    }

    func testEmails_itShouldReturnAllEmails() throws {
        sut = makeReaderWithMultipleCards()
        try sut.read()

        let emails = sut.emails(fromCardTypes: [.PlainText, .SignedOnly])
        XCTAssertEqual(emails.count, 4)
        XCTAssertEqual(emails[0].emailAddress, "fracle@example.com")
        XCTAssertEqual(emails[0].type, .home)
        XCTAssertEqual(emails[1].emailAddress, "clecle@proton.me")
        XCTAssertEqual(emails[1].type, .work)
        XCTAssertEqual(emails[2].emailAddress, "John-Appleseed@mac.com")
        XCTAssertEqual(emails[2].type.rawString, "X-INTERNET")
        XCTAssertEqual(emails[3].emailAddress, "john.as@example.com")
        XCTAssertEqual(emails[3].type.rawString, "X-INTERNET")
    }

    func testPhoneNumbers_itShouldReturnAllNumbers() throws {
        sut = makeReaderWithOnlyPlainVCard()
        try sut.read()

        let numbers = sut.phoneNumbers(fromCardTypes: [.PlainText])
        XCTAssertEqual(numbers.count, 2)
        XCTAssertEqual(numbers[0].number, "(349) 495-511")
        XCTAssertEqual(numbers[0].type, .custom("CELL"))
        XCTAssertEqual(numbers[1].number, "1 (234) 567-89")
        XCTAssertEqual(numbers[1].type, .home)
    }

    func testAddresses_itShouldReturnAllAddresses() throws {
        sut = makeReaderWithOnlyPlainVCard()
        try sut.read()

        let addresses = sut.addresses(fromCardTypes: [.PlainText])
        XCTAssertEqual(addresses.count, 1)
        XCTAssertEqual(addresses[0].street, "1600 Pennsylania Avenue")
        XCTAssertEqual(addresses[0].streetTwo, "")
        XCTAssertEqual(addresses[0].locality, "Washington D.C")
        XCTAssertEqual(addresses[0].region, "")
        XCTAssertEqual(addresses[0].postalCode, "20500")
        XCTAssertEqual(addresses[0].country, "United States")
        XCTAssertEqual(addresses[0].poBox, "")
    }

    func testUrls_itShouldReturnAllUrls() throws {
        sut = makeReaderWithOnlyPlainVCard()
        try sut.read()

        let urls = sut.urls(fromCardTypes: [.PlainText])
        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].url, "www.myhome.net")
        XCTAssertEqual(urls[0].type, .home)
    }

    func testOrganization_itShouldReturnAllOrganizations() throws {
        sut = makeReaderWithOnlyPlainVCard()
        try sut.read()

        let orgs = sut.otherInfo(infoType: .organization, fromCardTypes: [.PlainText])
        XCTAssertEqual(orgs.count, 1)
        XCTAssertEqual(orgs[0].value, "Proton A.G.")
        XCTAssertEqual(orgs[0].type, .organization)
    }

    func testBirthday_itShouldReturnAllBirthdays() throws {
        sut = makeReaderWithOnlyPlainVCard()
        try sut.read()

        let birthdays = sut.otherInfo(infoType: .birthday, fromCardTypes: [.PlainText])
        XCTAssertEqual(birthdays.count, 1)
        XCTAssertEqual(birthdays[0].value, "2020-01-01")
        XCTAssertEqual(birthdays[0].type, .birthday)
    }
}

private extension ProtonVCardsTests {

    func makeReaderWithOnlyPlainVCard() -> ProtonVCards {
        let cards = [CardData(type: .PlainText, data: testVCard, signature: "")]
        return ProtonVCards(cards: cards, userKeys: [], mailboxPassphrase: Passphrase(value: ""))
    }

    func makeReaderWithMultipleCards() -> ProtonVCards {
        let cards = [CardData(type: .PlainText, data: testVCard, signature: ""), testSignedCardData]
        return ProtonVCards(cards: cards, userKeys: [testCorrectArmoredKey], mailboxPassphrase: testCorrectPassphrase1)
    }

    var testSignedCardData: CardData {
        CardData(type: .SignedOnly, data: testCardSigned1, signature: testCardSignedSignature1)
    }

    var testSignedAndEncryptedCardData: CardData {
        CardData(type: .SignAndEncrypt, data: testCardSignedAndEncrypted2, signature: testCardSignedSignature2)
    }
}

private extension ProtonVCardsTests {

    var testCardSigned1: String {
    """
    BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nitem0.EMAIL;TYPE=INTERNET,WORK,pref:John-Appleseed@mac.com\r\nitem1.EMAIL;TYPE=INTERNET,HOME:john.as@example.com\r\nUID:410FE041-5C4E-48DA-B4DE-04C15EA3DBAC\r\nFN:John Appleseed\r\nEND:VCARD\r\n
    """
    }

    var testCardSignedSignature1: String {
    """
    -----BEGIN PGP SIGNATURE-----\nVersion: ProtonMail\n\nwnUEARYKACcFAmVeQIIJEDpWGY8tUvWiFiEEkwjBgOxaE4Ws92l+OlYZjy1S\n9aIAANPNAP9LDXWgJ0mcJwhpPTA13mPkDD1pWvd3cNHzB0SlERiCLQD/bG4g\ncDterXjOplYgHRjwPaapNQ2oQkvYXOUivNJeRAM=\n=vehn\n-----END PGP SIGNATURE-----\n
    """
    }

    var testCardSignedAndEncrypted2: String {
    """
    -----BEGIN PGP MESSAGE-----\nVersion: ProtonMail\n\nwV4Ds2QhTCgZJYYSAQdAAF+RecRmhLMt6NHsWGafzYfbyMRDYMYNJTsVxOiw\nnEwwJ6yP0Em/GU7UeUwSLzgcvShlhtuph1zU41d2FY/TtvdX4peDGauKjYw6\noqoQB7IK0sDSAYE4NbXGSsyDjwgpyEyHUgavKKvau69ADD3uLZpMrF01fe4s\nVrVuWvdxrGmHdqPDlH/BqK7H3Dc8CELFqA3Z8dqEr/3OSnt7eSEiXxYGXd12\nteodIYINJgEr/LyaajB9ZwKAtZfDtOSXW5dmOZzbecIaQ6u3aHpPxj67OynY\n1L025XgjzH+b2lm6wlH1gP+PXBXy68g3NWgcrrnM7JjLgPHYeIOymEk3d1ry\nOH+IYLeG7ydpGm9DwGNeJRd6qPmEtzTHd36tPNE23gPRWAEho4QWVgYw+TC8\n30Ru9+p1Adb57SHTzqGtUCW1PSMV62VrVJqMReiku+ezB4SL+TfxhfPp+zpv\nfEq2WArUxCy7qRTwhCXpp3fnNgu44LCNmlEqXb3D7KQFbmD3rri1X/jM2LqN\n66EGjnZkQR8oX7ztonUIskQIEDY2M/oA6xEXUl5t7Q1jFyrd8G1VQtENY+Wp\n97q//4X9h3KrFPFQc3klxtly+1D2Ve1bVY9a20Vi6IitpjGzlTbZUJ0Jtmn4\nfyF4JIp+\n=t+YZ\n-----END PGP MESSAGE-----\n
    """
    }

    var testCardSignedSignature2: String {
    """
    -----BEGIN PGP SIGNATURE-----\nVersion: ProtonMail\n\nwnUEARYKACcFAmVeQIIJEDpWGY8tUvWiFiEEkwjBgOxaE4Ws92l+OlYZjy1S\n9aIAACHEAP9oDnVNZ/t0mALN+8hBI4bw0BZ3p/0p4TgmZ8jdN8aMjAEA1GWV\nHrlmkCm3I251xP8Oh85VjC0ieoza4B6JOZEApwo=\n=dM2e\n-----END PGP SIGNATURE-----\n
    """
    }

    var testCorrectArmoredKey: ArmoredKey {
        ArmoredKey(value:
        """
        -----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: ProtonMail\n\nxYYEZUUC7RYJKwYBBAHaRw8BAQdADAS6LPy3U4JZMVSb8yKXc/L2BLL2BhW2\n0n/eNrw83Dj+CQMIZd6bvwVRDSpgXZAB8wEgbYyJb9ICRq77lm96BfCe4EoX\nYK89W3ypZwrWT/CPJM0f+kBn2jnZFnBW4HwX/4M3BqAkZdpBVNXTsC8fwYuW\nYc0leGF2aXFhMkBwcm90b24ubWUgPHhhdmlxYTJAcHJvdG9uLm1lPsKPBBMW\nCABBBQJlRQLtCRA6VhmPLVL1ohYhBJMIwYDsWhOFrPdpfjpWGY8tUvWiAhsD\nAh4BAhkBAwsJBwIVCAMWAAIFJwkCBwIAABjUAPsGqhKj0zOSL8SOaqb1dsW6\nZDWRT0SFs9mMRnCQC9CpiAEArI7RzYoliTnzzNNsbhG5T6as1GQNJi/eOaoN\ndo/UNQfHiwRlRQLtEgorBgEEAZdVAQUBAQdAcBYvWvM52G+dmzGdMmcakzus\nvbLqKE4mqeoLwDfkpFADAQoJ/gkDCMp4bpOEHumvYHLWEqksOBxIBBo74wsE\nE84TE4HMuTv1T7tbjogi6yiB6Tr3XUjuvNVkxWiJcRbVvfS8loFE1YbADQaG\noG8GgZ9u1/4dtz/CeAQYFggAKgUCZUUC7QkQOlYZjy1S9aIWIQSTCMGA7FoT\nhaz3aX46VhmPLVL1ogIbDAAAUEwBAJ+V7L31vCR2TqkyCW3aRZ4gACLbqDxe\noYdnlCUqEckRAQCyj8Ymn2PZyUbA5LY6zNK8tz6lYg7Xb8suppkBd4YYCg==\n=7X7G\n-----END PGP PRIVATE KEY BLOCK-----\n
        """
        )
    }

    var testCorrectPassphrase1: Passphrase {
        Passphrase(value: "mYxL20.KfmFnGJOivxCh3qBKAud/iEe")
    }

    var testIncorrectArmoredKey: ArmoredKey {
        ArmoredKey(value:
        """
        -----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: ProtonMail\n\nxRREZUUC7RYJKwYBBAHaRw8BAQdADAS6LPy3U4JZMVSb8yKXc/L2BLL2BhW2\n0n/eNrw83Dj+CQMIZd6bvwVRDSpgXZAB8wEgbYyJb9ICRq77lm96BfCe4EoX\nYK89W3ypZwrWT/CPJM0f+kBn2jnZFnBW4HwX/4M3BqAkZdpBVNXTsC8fwYuW\nYc0leGF2aXFhMkBwcm90b24ubWUgPHhhdmlxYTJAcHJvdG9uLm1lPsKPBBMW\nCABBBQJlRQLtCRA6VhmPLVL1ohYhBJMIwYDsWhOFrPdpfjpWGY8tUvWiAhsD\nAh4BAhkBAwsJBwIVCAMWAAIFJwkCBwIAABjUAPsGqhKj0zOSL8SOaqb1dsW6\nZDWRT0SFs9mMRnCQC9CpiAEArI7RzYoliTnzzMMsbhG5T6as1GQNJi/eOaoN\ndo/UNQfHiwRlRQLtEgorBgEEAZdVAQUBAQdAcBYvWvM52G+dmzGdMmcakzus\nvbLqKE4mqeoLwDfkpFADAQoJ/gkDCMp4bpOEHumvYHLWEqksOBxIBBo74wsE\nE84TE4HMuTv1T7tbjogi6yiB6Tr3XUjuvNVkxWiJcRbVvfS8loFE1YbADQaG\noG8GgZ9u1/4dtz/CeAQYFggAKgUCZUUC7QkQOlYZjy1S9aIWIQSTCMGA7FoT\nhaz3aX98VhmPLVL1ogIbDAAAUEwBAJ+V7L31vCR2TqkyCW3aRZ4gACLbqDxe\noYdnlCUqEckRAQCyj8Ymn2PZyUbA5LY6zNK8tz6lYg7Xb8suppkBd4YYCg==\n=7X7G\n-----END PGP PRIVATE KEY BLOCK-----\n
        """
        )
    }

    var testIncorrectPassphrase: Passphrase {
        Passphrase(value: "pYxL20.KfmFnGRWivxCh3qBKAud/iEw")
    }
}

private extension ProtonVCardsTests {

    var testVCard: String {
        """
        BEGIN:VCARD
        VERSION:3.0
        PRODID:-//Apple Inc.//iPhone OS 17.0//EN
        N:Clément;François;;;
        FN:François Clément
        ORG:Proton A.G.;
        EMAIL;type=HOME;type=pref:fracle@example.com
        EMAIL;type=WORK:clecle@proton.me
        TEL;type=CELL;type=VOICE;type=pref:(349) 495-511
        TEL;type=HOME;type=VOICE:1 (234) 567-89
        item1.ADR;type=WORK;type=pref:;;1600 Pennsylania Avenue;Washington D.C;;20500;United States
        item1.X-ABADR:us
        URL;type=HOME;type=pref:www.myhome.net
        BDAY:2020-01-01
        END:VCARD
        """
    }

}
