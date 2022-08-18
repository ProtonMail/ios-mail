//
//  ContactEditVIewModel.swift
//  Proton Mail - Created on 5/3/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

enum RuntimeError: Int, Error, CustomErrorVar {
    case invalidEmail = 0x0001

    var code: Int {
        return self.rawValue
    }

    var desc: String {
        return reason
    }

    var reason: String {
        switch self {

        case .invalidEmail:
            return LocalString._please_input_a_valid_email_address
        }
    }

}

class ContactEditViewModel: ContactEditViewModelContactGroupDelegate {

    var allowed_types: [InformationType] = [.organization,
                                            .nickname,
                                            .title,
                                            .gender,
                                            .birthday]

    typealias ContactEditSaveComplete = ((_ error: NSError?) -> Void)
    private(set) var user: UserManager
    let coreDataService: CoreDataService
    init(user: UserManager, coreDataService: CoreDataService) {
        self.user = user
        self.coreDataService = coreDataService
    }

    // table view 
    func getSections() -> [ContactEditSectionType] {
        fatalError("This method must be overridden")
    }
    func sectionCount() -> Int {
        fatalError("This method must be overridden")
    }

    func getLeftInfoTypes() -> [InformationType] {
        var out: [InformationType] = []
        for allowed in allowed_types {
            var found: Bool = false
            for info in getInformations() {
                if allowed == info.infoType {
                    found = true
                }
            }
            if !found {
                out.append(allowed)
            }
        }
        return out
    }

    func pick(newType supported: [ContactFieldType], pickedTypes: [ContactEditTypeInterface]) -> ContactFieldType {
        // TODO:: need to check the size
        var newType = supported[0] // get default
        for type in supported {
            var found = false
            for e in pickedTypes {
                if e.getCurrentType().rawString == type.rawString {
                    found = true
                    break
                }
            }

            if !found {
                newType = type
                break
            }
        }
        return newType
    }

    func getInformations() -> [ContactEditInformation] {
        fatalError("This method must be overridden")
    }

    // check view is new or update
    func isNew() -> Bool {
        fatalError("This method must be overridden")
    }

    func getEmails() -> [ContactEditEmail] {
         fatalError("This method must be overridden")
    }

    func getCells() -> [ContactEditPhone] {
        fatalError("This method must be overridden")
    }

    func getAddresses() -> [ContactEditAddress] {
        fatalError("This method must be overridden")
    }

    func getFields() -> [ContactEditField] {
        fatalError("This method must be overridden")
    }

    func getNotes() -> ContactEditNote {
        fatalError("This method must be overridden")
    }

    func getProfile() -> ContactEditProfile {
        fatalError("This method must be overridden")
    }

    func getProfilePicture() -> UIImage? {
        fatalError("This method must be overridden")
    }

    func setProfilePicture(image: UIImage?) {
        fatalError("This method must be overridden")
    }

    func profilePictureNeedsUpdate() -> Bool {
        fatalError("This method must be overridden")
    }

    func getUrls() -> [ContactEditUrl] {
        fatalError("This method must be overridden")
    }

    //
    func newUrl() -> ContactEditUrl {
        fatalError("This method must be overridden")
    }
    func deleteUrl(at index: Int) {
        fatalError("This method must be overridden")
    }
    func newEmail() -> ContactEditEmail {
        fatalError("This method must be overridden")
    }
    func deleteEmail(at index: Int) {
        fatalError("This method must be overridden")
    }

    func newPhone() -> ContactEditPhone {
        fatalError("This method must be overridden")
    }
    func deletePhone(at index: Int) {
        fatalError("This method must be overridden")
    }

    func newAddress() -> ContactEditAddress {
        fatalError("This method must be overridden")
    }
    func deleteAddress(at index: Int) {
        fatalError("This method must be overridden")
    }

    func newInformation(type: InformationType) -> ContactEditInformation {
        fatalError("This method must be overridden")
    }
    func deleteInformation(at index: Int) {
        fatalError("This method must be overridden")
    }

    func newField() -> ContactEditField {
        fatalError("This method must be overridden")
    }
    func deleteField(at index: Int) {
        fatalError("This method must be overridden")
    }

    func needsUpdate() -> Bool {
        let profile = self.getProfile()
        if profile.needsUpdate() {
            return true
        }
        for e in getEmails() {
            if e.needsUpdate() {
                return true
            }
        }

        // encrypted part
        for cell in getCells() {
            if cell.needsUpdate() {
                return true
            }
        }
        for addr in getAddresses() {
            if addr.needsUpdate() {
                return true
            }
        }
        for info in getInformations() {
            if info.needsUpdate() {
                return true
            }
        }
        for url in getUrls() {
            if url.needsUpdate() {
                return true
            }
        }

        let note = getNotes()
        if note.needsUpdate() {
            return true
        }

        for field in getFields() {
            if field.needsUpdate() {
                return true
            }
        }

        if profilePictureNeedsUpdate() {
            return true
        }

        return false
    }

    // actions
    func done(complete : @escaping ContactEditSaveComplete) {
        fatalError("This method must be overridden")
    }

    func delete(complete : @escaping ContactEditSaveComplete) {
        fatalError("This method must be overridden")
    }

    // contact group
    func getAllContactGroupCounts() -> [(ID: String, name: String, color: String, count: Int)] {
        fatalError("This method must be overridden")
    }

    func updateContactCounts(increase: Bool, contactGroups: Set<String>) {
        fatalError("This method must be overridden")
    }
}
