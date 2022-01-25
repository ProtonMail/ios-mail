// Copyright (c) 2021 Proton Technologies AG
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

import OpenPGP
import ProtonCore_DataModel
import XCTest
@testable import ProtonMail
import Contacts

final class ParserDelegate: NSObject, AppleContactParserDelegate {
    private(set) var progresses: [Double] = []
    private(set) var messages: [String] = []
    private(set) var error: String = ""
    @objc dynamic private(set) var shouldDismissImportPopup = false
    private(set) var shouldDisableCancel = false
    private(set) var uploaded: [AppleContactParsedResult] = []
    private(set) var existed: [String] = []

    func update(progress: Double) {
        self.progresses.append(progress)
    }

    func update(message: String) {
        self.messages.append(message)
    }

    func showParser(error: String) {
        self.error = error
    }

    func dismissImportPopup() {
        self.shouldDismissImportPopup = true
    }

    func disableCancel() {
        self.shouldDisableCancel = true
    }

    func updateUserData() -> (userKey: Key, passphrase: String, existedContactIDs: [String])? {
        let userKey = Key(keyID: "", privateKey: KeyTestData.privateKey1.rawValue)
        let passphrase = KeyTestData.passphrash1.rawValue
        return (userKey, passphrase, existed)
    }

    func scheduleUpload(data: AppleContactParsedResult) {
        self.uploaded.append(data)
    }

    func addExisted(id: String) {
        self.existed.append(id)
    }
}

final class AppleContactParserTest: XCTestCase {
    private var mockDelegate: ParserDelegate!
    private var coreDataService: CoreDataService!
    private var parser: AppleContactParser!
    private var dismissObserver: NSKeyValueObservation?

    override func setUpWithError() throws {
        self.mockDelegate = ParserDelegate()
        self.coreDataService = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        self.parser = AppleContactParser(delegate: mockDelegate,
                                         coreDataService: coreDataService)
    }

    override func tearDownWithError() throws {
        self.mockDelegate = nil
        self.coreDataService = nil
        self.parser = nil
    }

    func testQueueImport_emptyContacts() {
        self.parser.queueImport(contacts: [])
        XCTAssertEqual(self.mockDelegate.progresses.count, 1)
        XCTAssertEqual(self.mockDelegate.progresses.first, 100.0)
        XCTAssertEqual(self.mockDelegate.messages.first, LocalString._contacts_all_imported)
        XCTAssertEqual(self.mockDelegate.shouldDismissImportPopup, true)
    }

    func testQueueImport_oneExisted() {
        let randomData = self.generateRandomData(num: 1)
        let contacts = self.generateContact(by: randomData)
        let existed = contacts.first?.identifier ?? ""
        self.mockDelegate.addExisted(id: existed)
        self.parser.queueImport(contacts: contacts)

        let finish = expectation(description: "contacts import done")
        self.dismissObserver = self.mockDelegate.observe(\.shouldDismissImportPopup, options: [.new]) { child, change in
            guard let newValue = change.newValue else { return }
            if newValue {
                finish.fulfill()
            }
        }
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.mockDelegate.uploaded.count, 0)
        XCTAssertEqual(self.mockDelegate.progresses.count, 1)
    }

    func testQueueImport() {
        let randomData = self.generateRandomData(num: 3)
        let contacts = self.generateContact(by: randomData)
        let existed = contacts.first?.identifier ?? ""
        self.mockDelegate.addExisted(id: existed)
        self.parser.queueImport(contacts: contacts)

        let finish = expectation(description: "contacts import done")
        self.dismissObserver = self.mockDelegate.observe(\.shouldDismissImportPopup, options: [.new]) { child, change in
            guard let newValue = change.newValue else { return }
            if newValue {
                finish.fulfill()
            }
        }
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.mockDelegate.uploaded.count, 2)
        // 0, 0.33, 0.66,     0, 0.5
        // encryption         schedule upload
        XCTAssertEqual(self.mockDelegate.progresses.count, 5)

        let uploaded = self.mockDelegate.uploaded
        for i in 0..<uploaded.count {
            let result = uploaded[i]
            let data = randomData[i+1]
            let name = (data["givenName"] ?? "") + " " + (data["familyName"] ?? "")
            XCTAssertEqual(result.name, name)

            let mail = data["mailAddress"] ?? ""
            XCTAssertEqual(result.definedMails.first?.newEmail, mail)
            XCTAssertEqual(self.mockDelegate.messages[i], "Encrypting contacts...\(i + 1)")
        }
    }
}

extension AppleContactParserTest {
    func testParseContacts() {
        let randomData = self.generateRandomData(num: 4)
        let contacts = self.generateContact(by: randomData)
        let existed = contacts.first?.identifier ?? ""
        let userKey = Key(keyID: "", privateKey: KeyTestData.privateKey1.rawValue)
        let results = parser.parse(contacts: contacts, userKey: userKey, passphrase: KeyTestData.passphrash1.rawValue, existedContactIDs: [existed])
        XCTAssertEqual(results.count, randomData.count - 1)
        for i in 0..<results.count {
            let result = results[i]
            let data = randomData[i+1]
            let name = (data["givenName"] ?? "") + " " + (data["familyName"] ?? "")
            XCTAssertEqual(result.name, name)

            let mail = data["mailAddress"] ?? ""
            XCTAssertEqual(result.definedMails.first?.newEmail, mail)
            XCTAssertEqual(self.mockDelegate.messages[i], "Encrypting contacts...\(i + 1)")
        }
    }

    func testParseFormattedName() {
        guard var vCard = PMNIVCard.createInstance() else {
            XCTFail()
            return
        }
        let caseUnknown = self.parser.parseFormattedName(from: vCard)
        XCTAssertNotNil(caseUnknown)
        XCTAssertEqual(caseUnknown?.1, LocalString._general_unknown_title)

        guard let formattedNameEmpty = PMNIFormattedName.createInstance(String.empty) else {
            XCTFail()
            return
        }
        vCard = PMNIVCard.createInstance()!
        vCard.setFormattedName(formattedNameEmpty)
        let caseEmpty = self.parser.parseFormattedName(from: vCard)
        XCTAssertNotNil(caseEmpty)
        XCTAssertEqual(caseEmpty?.1, LocalString._general_unknown_title)

        let name = "Sheldon Cooper"
        guard let formattedName = PMNIFormattedName.createInstance("  \(name)     ") else {
            XCTFail()
            return
        }
        vCard = PMNIVCard.createInstance()!
        vCard.setFormattedName(formattedName)
        let caseName = self.parser.parseFormattedName(from: vCard)
        XCTAssertNotNil(caseName)
        XCTAssertEqual(caseName?.1, name)
    }

    func testParseEmails() {
        let mail1 = PMNIEmail.createInstance("WORK", email: "eifh@eif.ei", group: "groupA")
        let mail2 = PMNIEmail.createInstance("OTHER", email: "aaa@eif.ei", group: "")
        let vCard = PMNIVCard.createInstance()!
        vCard.add(mail1)
        vCard.add(mail2)
        let result = self.parser.parseEmails(from: vCard)
        XCTAssertEqual(result.0.count, 2)
        XCTAssertEqual(result.0[0].getValue(), "eifh@eif.ei")
        XCTAssertEqual(result.0[0].getTypes(), ["WORK"])
        XCTAssertEqual(result.0[0].getGroup(), "groupA")
        XCTAssertEqual(result.0[1].getValue(), "aaa@eif.ei")
        XCTAssertEqual(result.0[1].getTypes(), ["OTHER"])
        XCTAssertEqual(result.0[1].getGroup(), "EItem1")
        XCTAssertEqual(result.1.count, 2)
        XCTAssertEqual(result.1[0].getCurrentType(), .work)
        XCTAssertEqual(result.1[0].newEmail, "eifh@eif.ei")
        XCTAssertEqual(result.1[0].getContactGroupNames(), [])
        XCTAssertEqual(result.1[1].getCurrentType(), .other)
        XCTAssertEqual(result.1[1].newEmail, "aaa@eif.ei")
        XCTAssertEqual(result.1[1].getContactGroupNames(), [])
    }

    func testUploadParsedResults() {
        let total = Int.random(in: 1...9)
        var results: [AppleContactParsedResult] = []
        for i in 0..<total {
            results.append(AppleContactParsedResult(cardDatas: [],
                                                    name: "name_\(i)",
                                                    definedMails: []))
        }
        XCTAssertEqual(results.count, total)
        self.parser.upload(parsedResults: results)
        XCTAssertTrue(self.mockDelegate.shouldDismissImportPopup)
        let progresses = self.mockDelegate.progresses
        XCTAssertEqual(progresses.count, total)
        let uploaded = self.mockDelegate.uploaded
        XCTAssertEqual(uploaded.count, total)
        XCTAssertEqual(uploaded[0].name, "name_0")
        XCTAssertEqual(uploaded.last?.name, "name_\(total - 1)")
    }
}

extension AppleContactParserTest {
    func testUpdateProgressByTotalAndCurrent() {
        self.parser.updateProgress(total: 10, current: 3)
        let progresses = self.mockDelegate.progresses
        XCTAssertEqual(progresses.count, 1)
        XCTAssertEqual(progresses[0], 0.3)
    }

    func testCreateFormattedName() {
        let name = "   Sheldon Cooper   "
        guard let (_, refinedName) = self.parser.createFormattedName(by: name) else {
            XCTFail("The formatted name shouldn't be nil")
            return
        }
        XCTAssertEqual(refinedName, "Sheldon Cooper")
    }

    func testCreateEditEmail() {
        let object = self.parser.createEditEmail(order: 3, type: .address, address: "abc@ma.il")
        XCTAssertEqual(object?.getCurrentType(), .address)
        XCTAssertEqual(object?.newEmail, "abc@ma.il")
    }

    func testRemoveEItem_WithoutEItem() {
        let data = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nitem1.EMAIL;TYPE=INTERNET:school@mail.com\r\nitem2.EMAIL;TYPE=INTERNET:iclould@mail.com\r\nitem3.EMAIL;TYPE=INTERNET:other@mail.com\r\nUID:C803E418-93A5-4816-B2ED-0A169F502BC4:ABPerson\r\nFN:Anc Fake\r\nEND:VCARD\r\n"
        let transferred = self.parser.removeEItem(vCard2Data: data)
        XCTAssertEqual(data, transferred)
    }

    func testRemoveEItem_Success() {
        let data = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nEItem1.EMAIL;TYPE=INTERNET,HOME,pref:home@mail.com\r\nEItem2.EMAIL;TYPE=INTERNET,WORK:work@mail.com\r\nitem1.EMAIL;TYPE=INTERNET:school@mail.com\r\nitem2.EMAIL;TYPE=INTERNET:iclould@mail.com\r\nitem3.EMAIL;TYPE=INTERNET:other@mail.com\r\nUID:C803E418-93A5-4816-B2ED-0A169F502BC4:ABPerson\r\nFN:Anc Fake\r\nEND:VCARD\r\n"
        let expected = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nitem4.EMAIL;TYPE=INTERNET,HOME,pref:home@mail.com\r\nitem5.EMAIL;TYPE=INTERNET,WORK:work@mail.com\r\nitem1.EMAIL;TYPE=INTERNET:school@mail.com\r\nitem2.EMAIL;TYPE=INTERNET:iclould@mail.com\r\nitem3.EMAIL;TYPE=INTERNET:other@mail.com\r\nUID:C803E418-93A5-4816-B2ED-0A169F502BC4:ABPerson\r\nFN:Anc Fake\r\nEND:VCARD\r\n"
        let transferred = self.parser.removeEItem(vCard2Data: data)
        XCTAssertEqual(expected, transferred)
    }

    func testRemoveEItem_EmptyInput() {
        let data = ""
        let transferred = self.parser.removeEItem(vCard2Data: data)
        XCTAssertEqual(transferred, data)
    }
}

extension AppleContactParserTest {
    func generateRandomData(num: Int) -> [[String: String]] {
        var data: [[String: String]] = []
        for _ in 0..<num {
            let familyName = String.randomString(Int.random(in: 1...5))
            let givenName = String.randomString(Int.random(in: 1...5))
            let mailAddress = String.randomEmailAddress()
            let phone = String.randomPhone(10)
            let dict = ["familyName": familyName,
                       "givenName": givenName,
                       "mailAddress": mailAddress,
                       "phone": phone]
            data.append(dict)
        }
        return data
    }

    func generateContact(by randomData: [[String: String]]) -> [CNMutableContact] {
        var contacts: [CNMutableContact] = []
        for data in randomData {
            let contact = CNMutableContact()
            contact.familyName = data["familyName"] ?? ""
            contact.givenName = data["givenName"] ?? ""

            let phone = CNPhoneNumber(stringValue: data["phone"] ?? "")
            let phoneLabel = CNLabeledValue(label: CNLabelHome, value: phone)
            contact.phoneNumbers = [phoneLabel]

            let mailAddress: NSString = (data["mailAddress"] ?? "") as NSString
            let mailLabel = CNLabeledValue(label: CNLabelWork, value: mailAddress)
            contact.emailAddresses = [mailLabel]

            contacts.append(contact)
        }
        return contacts
    }
}
