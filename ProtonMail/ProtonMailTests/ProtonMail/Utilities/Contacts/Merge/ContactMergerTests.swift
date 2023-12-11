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

import ProtonCoreDataModel
import ProtonCoreCrypto
import ProtonCoreUtilities
@testable import ProtonMail
import XCTest
import VCard

final class ContactMergerTests: XCTestCase {
    private var sut: ContactMerger!

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testMerge_withAutoImport_itReturnsContactEntityWithMergedData() throws {
        sut = try ContactMerger(
            deviceContact: deviceContact,
            protonContact: contactEntity,
            userKeys: userKeys,
            mailboxPassphrase: passphrase
        )

        let result = try sut.merge(strategy: AutoImportStrategy()).contactEntity
        
        XCTAssertTrue(result != nil)
        XCTAssertEqual(result?.cardDatas.count, 2)


        // signed vCard
        let signedVCard: String! = result?.cardDatas.filter({ $0.type == .SignedOnly }).first?.data
        let pmniCard1 = PMNIEzvcard.parseFirst(signedVCard)

        XCTAssertEqual(pmniCard1?.getStructuredName()?.getGiven(), "Kathy")
        XCTAssertEqual(pmniCard1?.getStructuredName()?.getFamily(), "Bell")

        let emails = pmniCard1?.getEmails().map { $0.getValue() }
        XCTAssertEqual(emails, ["kate-bell@mac.com", "kate-bell@proton.me"])


        // encrypted vCard

        let encryptedVCard: String! = result?.cardDatas.filter({ $0.type == .SignAndEncrypt }).first?.data
        let decryptedVCard = try encryptedVCard.decryptMessageWithSingleKeyNonOptional(
            ArmoredKey(value: userKeys.first!.privateKey),
            passphrase: passphrase
        )
        let pmniCard2 = PMNIEzvcard.parseFirst(decryptedVCard)
        let phoneNumbers = pmniCard2?.getTelephoneNumbers().map { $0.getText() }
        XCTAssertEqual(phoneNumbers, ["(555) 564-8583", "(415) 555-3695", "555-478-7672"])

        let addresses = pmniCard2?.getAddresses()
        XCTAssertEqual(addresses?.count, 2)

        let organization = pmniCard2?.getOrganizations().map({ $0.getValue() }).first
        XCTAssertEqual(organization, "Proton")

        let nickname = pmniCard2?.getNickname().map({ $0.getNickname() })
        XCTAssertEqual(nickname, "KAT")
    }
}

private extension Either<DeviceContact, ContactEntity> {
    var contactEntity: ContactEntity? {
        switch self {
        case .right(let result): return result
        case .left: return nil
        }
    }
}

extension ContactMergerTests {

    var deviceContact: DeviceContact {
        DeviceContact(
            identifier: .init(uuid: "", emails: []),
            fullName: nil,
            vCard:
            """
            BEGIN:VCARD
            VERSION:4.0
            FN;PREF=1:Kathy Bell
            X-ABADR:us
            TEL;TYPE="HOME,VOICE,pref";PREF=1:555-478-7672
            N:Bell;Kathy;;;
            NICKNAME:KAT
            ORG:Proton;
            ADR;TYPE="HOME,pref";PREF=1:;;332 Laguna Street;Corte Madera;CA;94925;USA
            PRODID;TYPE=text;VALUE=TEXT:pm-ez-vcard 0.0.1
            EMAIL;TYPE="HOME";PREF=1:kate-bell@proton.me
            UID:AB211C5F-9EC9-429F-9466-B9382FF61035
            END:VCARD
            """
        )
    }

    var contactEntity: ContactEntity {
        ContactEntity.make(cardData: contactCardData)
    }

    /**
     This is the content that should be in the contact card data:

     BEGIN:VCARD
     VERSION:3.0
     PRODID:-//Apple Inc.//iPhone OS 17.0//EN
     N:Bell;Kate;;;
     FN:Kate Bell
     ORG:Creative Consulting;
     TITLE:Producer
     EMAIL;type=INTERNET;type=WORK;type=pref:kate-bell@mac.com
     TEL;type=MAIN;type=pref:(415) 555-3695
     TEL;type=CELL;type=VOICE:(555) 564-8583
     item1.ADR;type=WORK;type=pref:;;165 Davis Street;Hillsborough;CA;94010;
     item1.X-ABADR:us
     item2.URL;type=pref:www.icloud.com
     item2.X-ABLabel:_$!<HomePage>!$_
     BDAY:1978-01-20
     END:VCARD
     */
    var contactCardData: String {
        "[{\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKACcFAmVp8BQJEDpWGY8tUvWiFiEEkwjBgOxaE4Ws92l+OlYZjy1S\\n9aIAAHigAQChQNRcuoGjc15HUOB4NB665uSW\\/wFmpQI+NpFTQLbSJQEAlBiZ\\nHjt0xZIcKreucx9QWHYWr5QTGeYp\\/E1txRWfmwo=\\n=bRKB\\n-----END PGP SIGNATURE-----\\n\",\"Type\":2,\"Data\":\"BEGIN:VCARD\\r\\nVERSION:4.0\\r\\nPRODID:pm-ez-vcard 0.0.1\\r\\nUID:protonmail-ios-EABDB6DD-7633-48F6-A58D-3506FAF07015\\r\\nFN:Kate Bell\\r\\nItem1.EMAIL;TYPE=INTERNET:kate-bell@mac.com\\r\\nEND:VCARD\\r\\n\"},{\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKACcFAmVp8BQJEDpWGY8tUvWiFiEEkwjBgOxaE4Ws92l+OlYZjy1S\\n9aIAAPavAP9Gyg5zXmsdIt28Ap3z41k0sy20qiinwqsJbvQ3Xt40SgD\\/Qg0Q\\nP3daJDgY9VXswEZ2rDO8zY4k\\/KVuGyg2JhmEyw8=\\n=13AW\\n-----END PGP SIGNATURE-----\\n\",\"Type\":3,\"Data\":\"-----BEGIN PGP MESSAGE-----\\nVersion: ProtonMail\\n\\nwV4Ds2QhTCgZJYYSAQdAPaet9HkFCQ8lWtAXx+wvGxGSomZpw87D6GFtmIRB\\nmVkwhg7tqClgT6UXGTSYhDIs9ob17wzZIAdln4jxgmv7CgtYbB3OSrwF8qOS\\nXLDLlc1M0sCVAQYvm\\/GBPoWYKXZlgPcM+LRpk0vHpx5VIqznJPlP915i6OZ9\\n5tBkIFLwcn6WU7qZN610Ck28GcBFm2GiFYvyb3qthYqhSdpdahAb+ijRR\\/tc\\nMWxMi6M0qgk7qQtxlgvRTq1lIANDOaRwI7wIzE8RaeZ8hsJ8pAH2mToDRmkO\\nDkv4GCTxETXpMWMPk0E00y3rxAfUm44paykcNTJF57WLPivcj\\/jYRRbR\\/LwZ\\nAX7ghHj9rT5eaJNNqO27xNdjiOeVbsaZjOQ28iVa6cIxRwf6B8O1DLICt+Ls\\nHCoP45A3IgsxGwzAeyOlno724vgDFScTWQk8UPd\\/\\/wu6Z0bUdnUi8nW+wFv4\\nw32rO2KyvNK\\/M8mPn1UcareSjM+Y1rBF820UmzrK7OjHMxb2WuJpPQgJWDPS\\nMimPieldNLV0g7e+T6yTbrVgQ\\/YjXkQ5qpiZWd57g7R4nHA=\\n=Yhx1\\n-----END PGP MESSAGE-----\\n\"}]"
    }

    var userKeys: [Key] {
        [Key(keyID: "1", privateKey: privateKey)]
    }

    var privateKey: String {
        "-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: ProtonMail\n\nxYYEZUUC7RYJKwYBBAHaRw8BAQdADAS6LPy3U4JZMVSb8yKXc/L2BLL2BhW2\n0n/eNrw83Dj+CQMIZd6bvwVRDSpgXZAB8wEgbYyJb9ICRq77lm96BfCe4EoX\nYK89W3ypZwrWT/CPJM0f+kBn2jnZFnBW4HwX/4M3BqAkZdpBVNXTsC8fwYuW\nYc0leGF2aXFhMkBwcm90b24ubWUgPHhhdmlxYTJAcHJvdG9uLm1lPsKPBBMW\nCABBBQJlRQLtCRA6VhmPLVL1ohYhBJMIwYDsWhOFrPdpfjpWGY8tUvWiAhsD\nAh4BAhkBAwsJBwIVCAMWAAIFJwkCBwIAABjUAPsGqhKj0zOSL8SOaqb1dsW6\nZDWRT0SFs9mMRnCQC9CpiAEArI7RzYoliTnzzNNsbhG5T6as1GQNJi/eOaoN\ndo/UNQfHiwRlRQLtEgorBgEEAZdVAQUBAQdAcBYvWvM52G+dmzGdMmcakzus\nvbLqKE4mqeoLwDfkpFADAQoJ/gkDCMp4bpOEHumvYHLWEqksOBxIBBo74wsE\nE84TE4HMuTv1T7tbjogi6yiB6Tr3XUjuvNVkxWiJcRbVvfS8loFE1YbADQaG\noG8GgZ9u1/4dtz/CeAQYFggAKgUCZUUC7QkQOlYZjy1S9aIWIQSTCMGA7FoT\nhaz3aX46VhmPLVL1ogIbDAAAUEwBAJ+V7L31vCR2TqkyCW3aRZ4gACLbqDxe\noYdnlCUqEckRAQCyj8Ymn2PZyUbA5LY6zNK8tz6lYg7Xb8suppkBd4YYCg==\n=7X7G\n-----END PGP PRIVATE KEY BLOCK-----\n"
    }

    var passphrase: Passphrase {
        Passphrase(value: "mYxL20.KfmFnGJOivxCh3qBKAud/iEe")
    }
}

