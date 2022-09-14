// Copyright (c) 2021 Proton AG
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
import Foundation
import OpenPGP
import ProtonCore_Crypto
import ProtonCore_DataModel

struct AppleContactParsedResult {
    let cardDatas: [CardData]
    let name: String
    let definedMails: [ContactEditEmail]
}

protocol AppleContactParserDelegate: AnyObject {
    func update(progress: Double)
    func update(message: String)
    func showParser(error: String)
    func dismissImportPopup()
    func disableCancel()
    func updateUserData() -> (userKey: Key, passphrase: Passphrase, existedContactIDs: [String])?
    func scheduleUpload(data: AppleContactParsedResult)
}

protocol AppleContactParserProtocol {
    func queueImport(contacts: [CNContact])
    func cancelImportTask()
}

final class AppleContactParser: AppleContactParserProtocol {
    private let contactImportQueue = OperationQueue()
    private var contactImportTask: BlockOperation?
    private weak var coreDataService: CoreDataService?
    private weak var delegate: AppleContactParserDelegate?

    init(delegate: AppleContactParserDelegate,
         coreDataService: CoreDataService) {
        self.delegate = delegate
        self.coreDataService = coreDataService
    }

    func queueImport(contacts: [CNContact]) {
        guard contacts.isEmpty == false else {
            self.delegate?.update(progress: 100)
            self.delegate?.update(message: LocalString._contacts_all_imported)
            self.delegate?.dismissImportPopup()
            return
        }
        guard self.contactImportTask == nil else { return }

        let task = BlockOperation()
        task.addExecutionBlock { [weak self] in
            guard let self = self,
                  let (userKey, passphrase, existed) = self.delegate?.updateUserData() else {
                      self?.delegate?.update(message: LocalString._contacts_import_error)
                      self?.delegate?.dismissImportPopup()
                      return
                  }
            let parsedResults = self.parse(contacts: contacts,
                                           userKey: userKey,
                                           passphrase: passphrase,
                                           existedContactIDs: existed)
            guard self.contactImportTask?.isCancelled == false else {
                self.delegate?.dismissImportPopup()
                return
            }
            guard !parsedResults.isEmpty else {
                self.delegate?.dismissImportPopup()
                return
            }
            CoreDataService.shouldIgnoreContactUpdateInMainContext = true
            defer {
                CoreDataService.shared.performAndWaitOnRootSavingContext { context in
                    context.refreshAllObjects()
                }
                CoreDataService.shared.mainContext.performAndWait {
                    CoreDataService.shared.mainContext.refreshAllObjects()
                }
            }
            self.delegate?.disableCancel()
            self.upload(parsedResults: parsedResults)
        }
        self.contactImportQueue.addOperation(task)
        self.contactImportTask = task
    }

    func cancelImportTask() {
        guard let task = self.contactImportTask else { return }
        task.cancel()
        self.contactImportTask = nil
        self.delegate?.update(message: LocalString._contacts_cancelling_title)
        self.delegate?.dismissImportPopup()
    }

}

extension AppleContactParser {
    func parse(contacts: [CNContact],
               userKey: Key,
               passphrase: Passphrase,
               existedContactIDs: [String]) -> [AppleContactParsedResult] {
        var parsedResults: [AppleContactParsedResult] = []

        let total = contacts.count
        var valid: Int = 0
        for (index, contact) in contacts.enumerated() {
            if ProcessInfo.isRunningUnitTests == false,
               self.contactImportTask?.isCancelled ?? true {
                return []
            }
            self.updateProgress(total: total, current: index)

            let identifier = contact.identifier
            guard !existedContactIDs.contains(identifier) else { continue }

            let name = contact.givenName + contact.familyName
            guard let rawData = try? CNContactVCardSerialization.data(with: [contact]),
                  let result = self.parse(contactData: rawData,
                                          identifier: identifier,
                                          name: name,
                                          userKey: userKey,
                                          passphrase: passphrase) else {
                      continue
                  }
            parsedResults.append(result)

            valid += 1
            self.delegate?.update(message: "Encrypting contacts...\(valid)")
        }
        return parsedResults
    }

    func parse(contactData: Data,
               identifier: String,
               name: String,
               userKey: Key,
               passphrase: Passphrase) -> AppleContactParsedResult? {
        guard let vCardStr = String(data: contactData, encoding: .utf8),
              let vCard3 = PMNIEzvcard.parseFirst(vCardStr),
              let vCard2 = PMNIVCard.createInstance() else {
                  let error = "Error happens when imports \(name)"
                  self.delegate?.showParser(error: error)
                  return nil
              }

        /* not included into requested keys since iOS 13 SDK, see comment in AddressBookService.getAllContacts() */
        // let note = contact.note

        var contactName = LocalString._general_unknown_title
        if let (fName, name) = self.parseFormattedName(from: vCard3) {
            vCard2.setFormattedName(fName)
            contactName = name
        }
        vCard3.clearFormattedName()

        let (vCard2Emails, contactEmails) = self.parseEmails(from: vCard3)
        vCard3.clearEmails()
        vCard2.setEmails(vCard2Emails)

        let uuid = PMNIUid.createInstance(identifier)
        guard let card2 = self.createCard2(by: vCard2,
                                           uuid: uuid,
                                           userKey: userKey,
                                           passphrase: passphrase),
              let card3 = self.createCard3(by: vCard3,
                                           userKey: userKey,
                                           passphrase: passphrase,
                                           uuid: uuid) else {
                  let error = "Error happens when encrypts \(name)"
                  self.delegate?.showParser(error: error)
                  return nil
              }

        let cards = [card2, card3]
        return AppleContactParsedResult(cardDatas: cards, name: contactName, definedMails: contactEmails)
    }

    func parseFormattedName(from vCard3: PMNIVCard) -> (PMNIFormattedName, String)? {
        let unknown = LocalString._general_unknown_title
        guard let fName = vCard3.getFormattedName() else {
            return self.createFormattedName(by: unknown)
        }

        let name = self.refine(fName)
        let source = name.isEmpty ? unknown : name
        return self.createFormattedName(by: source)
    }

    func parseEmails(from vCard3: PMNIVCard) -> ([PMNIEmail], [ContactEditEmail]) {
        var vCard2Emails: [PMNIEmail] = []
        var contactEmails: [ContactEditEmail] = []

        let vCardEmails = vCard3.getEmails()
        var idx: Int = 1
        for email in vCardEmails {
            let groupName = "EItem\(idx)"
            let group = email.getGroup()
            if group.isEmpty {
                email.setGroup(groupName)
                idx += 1
            }
            let mailAddress = email.getValue()
            let type = email
                .getTypes()
                .map({ ContactFieldType(raw: $0) })
                .first(where: { $0 != .empty }) ?? .empty
            guard mailAddress.isValidEmail(),
                  let object = self.createEditEmail(order: idx,
                                                    type: type,
                                                    address: mailAddress) else {
                      continue
                  }
            vCard2Emails.append(email)
            contactEmails.append(object)
        }
        return (vCard2Emails, contactEmails)
    }

    func upload(parsedResults: [AppleContactParsedResult]) {
        let total = parsedResults.count
        for (index, result) in parsedResults.enumerated() {
            self.delegate?.scheduleUpload(data: result)
            self.updateProgress(total: total, current: index)
        }
        self.delegate?.dismissImportPopup()
    }
}

extension AppleContactParser {
    func updateProgress(total: Int, current: Int) {
        let progress = Double(current) / Double(total)
        self.delegate?.update(progress: progress)
    }

    func refine(_ formattedName: PMNIFormattedName) -> String {
        formattedName
            .getValue()
            .trim()
            .preg_replace("  ", replaceto: " ")
    }

    func createFormattedName(by name: String) -> (PMNIFormattedName, String)? {
        let name = name
            .trim()
            .preg_replace("  ", replaceto: " ")
        if let defaultName = PMNIFormattedName.createInstance(name) {
            let contactName = self.refine(defaultName)
            return (defaultName, contactName)
        }
        return nil
    }

    func createEditEmail(order: Int, type: ContactFieldType, address: String) -> ContactEditEmail? {
        guard let service = self.coreDataService else { return nil }
        return ContactEditEmail(order: order,
                                type: type,
                                email: address,
                                isNew: true,
                                keys: nil,
                                contactID: nil,
                                encrypt: nil,
                                sign: nil,
                                scheme: nil,
                                mimeType: nil,
                                delegate: nil,
                                coreDataService: service)
    }

    /// Transfer EItem prefix to item prefix
    /// Some of data starts with EItem
    /// e.g. EItem1.EMAIL;TYPE=INTERNET,HOME,pref:home@mail.com
    /// We need to transfer the prefix to Item with the correct item order
    /// - Parameter vCard2Data: Original vCard2 string data
    /// - Returns: Transferred vCard2 string data
    func removeEItem(vCard2Data: String) -> String {
        var splits = vCard2Data.split(separator: "\r\n").map { String($0) }
        let eItemIndex = splits.indices
            .filter { splits[$0].hasPrefix("EItem") }
        guard !eItemIndex.isEmpty else { return vCard2Data }

        let maxIndex = splits.filter { $0.hasPrefix("item") }
            .map { str -> Int in
                guard let itemStr = str.split(separator: ".").first else {
                    return -1
                }
                let index = itemStr.index(str.startIndex, offsetBy: 4)
                return Int(itemStr[index...]) ?? -1
            }
            .max() ?? -1
        var newIndex = maxIndex + 1
        for index in eItemIndex {
            let item = splits[index]
            guard let prefix = item.split(separator: ".").first,
                  let range = item.range(of: prefix) else {
                continue
            }

            let suffix = item[range.upperBound...]
            splits[index] = "item\(newIndex)\(suffix)"
            newIndex += 1
        }
        let newData = splits.joined(separator: "\r\n")
        return newData + "\r\n"
    }

    func createCard2(by vCard2: PMNIVCard,
                     uuid: PMNIUid?,
                     userKey: Key,
                     passphrase: Passphrase) -> CardData? {
        vCard2.setUid(uuid)
        vCard2.purifyGroups()
        guard var vCardString = try? vCard2.write() else {
            return nil
        }
        vCardString = self.removeEItem(vCard2Data: vCardString)
        guard let signature = try? Crypto()
                .signDetached(plainText: vCardString,
                              privateKey: userKey.privateKey,
                              passphrase: passphrase.value) else {
                    return nil
                }
        let card = CardData(t: .SignedOnly, d: vCardString, s: signature)
        return card
    }

    func createCard3(by vCard3: PMNIVCard,
                     userKey: Key,
                     passphrase: Passphrase,
                     uuid: PMNIUid?,
                     version: PMNIVCardVersion? = PMNIVCardVersion.vCard40()) -> CardData? {
        vCard3.setUid(uuid)
        vCard3.setVersion(version)
        vCard3.purifyGroups()
        guard let vCardString = try? vCard3.write(),
              let signature = try? Crypto()
                .signDetached(plainText: vCardString,
                              privateKey: userKey.privateKey,
                              passphrase: passphrase.value) else {
                    return nil
                }
        let encrypted = try? vCardString.encryptNonOptional(withPubKey: userKey.publicKey,
                                                            privateKey: "",
                                                            passphrase: "")
        let card = CardData(t: .SignAndEncrypt, d: encrypted ?? "", s: signature)
        return card
    }
}
