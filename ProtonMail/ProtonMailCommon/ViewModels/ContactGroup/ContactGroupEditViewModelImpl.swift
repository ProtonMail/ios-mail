//
//  ContactGroupEditViewModelImpl.swift
//  Proton Mail - Created on 2018/8/21.
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

import Foundation
import PromiseKit

/*
 TODO:
 
 1. Use the return value (confirmation) of the API call to update the view model. Currently, the code updates it locally without considering if the API call is successfully or not
 */
class ContactGroupEditViewModelImpl: ContactGroupEditViewModel {
    
    /// the state of the controller, can only be either create or edit
    var state: ContactGroupEditViewControllerState

    /// the contact group data
    var contactGroup: ContactGroupData {
        didSet {
            self.prepareEmailArray()
        }
    }

    /// all of the emails in the contact group
    /// not using NSSet so the tableView can easily get access to a specific row
    var emailsInGroup: [EmailEntity]
    
    /// this array structures the layout of the tableView in ContactGroupEditViewController
    var tableContent: [[ContactGroupEditTableCellType]]

    /// this array holds the section titles for the tableView
    var tableSectionTitle: [String]

    /// for updating the ContactGroupEditViewController
    weak var delegate: ContactGroupEditViewControllerDelegate?

    private(set) var user: UserManager
    var contactGroupService: ContactGroupsDataService

    /**
     Setup the view model
     */
    init(state: ContactGroupEditViewControllerState = .create,
         user: UserManager,
         groupID: String? = nil,
         name: String?,
         color: String?,
         emailIDs: Set<EmailEntity>) {
        self.state = state
        self.emailsInGroup = []
        self.tableContent = []
        self.tableSectionTitle = []
        self.contactGroup = ContactGroupData(ID: groupID,
                                             name: name,
                                             color: color,
                                             emailIDs: emailIDs)
        self.user = user
        self.contactGroupService = user.contactGroupService
        self.prepareEmailArray()
    }

    /**
     Reset the tableView content to basic elements only
     
     This is called automatically in the updateTableContent(emailCount:)
     */
    private func resetTable() {
        // content
        self.tableContent = [
            [.manageContact],
            []
        ]

        if self.state == .edit {
            self.tableContent.append([.deleteGroup])
        }

        // title
        self.tableSectionTitle = [
            "",
            "",
            ""
        ]

        if self.state == .edit {
            self.tableSectionTitle.append("")
        }
    }

    /**
     Add email fields to the tableContent array
     
     - Parameter emailCount: the email fields to be added to the tableContent array
     */
    private func updateTableContent(emailCount: Int) {
        resetTable()

        for _ in 0..<emailCount {
            self.tableContent[1].append(.email)
        }

        if emailCount == 0 {
            tableSectionTitle[1] = ""
        } else {
            tableSectionTitle[1] = String(format: LocalString._contact_groups_member_count_description,
                                          emailCount)
        }
    }

    /**
     Load email content and prepare the tableView for displaying them
     */
    private func prepareEmailArray() {
        self.emailsInGroup = Array(self.contactGroup.emailIDs)
            .sorted { first, second in
                if first.name == second.name {
                    return first.email < second.email
                }
                return first.name < second.name
            }
        // update
        updateTableContent(emailCount: self.emailsInGroup.count)
        self.delegate?.updateAddressSection()
    }

    /**
     - Parameter name: The name of the contact group to be set to
     
     // TODO: bundle it with the textField delegate, so we can keep the contactGroup status up-to-date
     */
    func setName(name: String) {
        contactGroup.name = name.isEmpty ? nil: name
    }

    /**
     - Parameter color: The color of the contact group to be set to. Notice that is the color is nil, the default color will be used
     */
    func setColor(newColor: String) {
        contactGroup.color = newColor
        self.delegate?.update()
    }

    /**
     - Parameter emails: Set the emails that will be in the contact group
     */
    func setEmails(emails: Set<EmailEntity>) {
        contactGroup.emailIDs = emails
    }

    /**
     Remove an email from the listing in the contact group.
     */
    func removeEmail(emailID: EmailID) {
        guard let idx = self.contactGroup.emailIDs.firstIndex(where: { $0.emailID == emailID }) else { return }
        self.contactGroup.emailIDs.remove(at: idx)
        self.prepareEmailArray()
    }

    /**
     - Returns: the title for the ContactGroupEditViewController
     */
    func getViewTitle() -> String {
        switch state {
        case .create:
            return ""
        case .edit:
            return LocalString._contact_groups_edit
        }
    }

    /**
     - Returns: the contact group name
     */
    func getName() -> String {
        return contactGroup.name ?? ""
    }

    /**
     - Returns: the color of the contact group
     */
    func getColor() -> String {
        return contactGroup.color
    }

    /**
     - Returns: the emails in the contact group
     */
    func getEmails() -> Set<EmailEntity> {
        return contactGroup.emailIDs
    }

    /**
     - Returns: the section title
     */
    func getSectionTitle(for section: Int) -> String {
        guard section < tableSectionTitle.count else {
            return ""
        }
        return tableSectionTitle[section]
    }

    /* Data operation */

    /**
     Saves the contact group to the server and cache
     
     This function will perform data checking,
     and it will decide which function to call for create/update
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     
     - Returns: Promise<Void>
     */
    func saveDetail() -> Promise<Void> {
        return firstly {
            () -> Promise<Void> in
            let (promise, seal) = Promise<Void>.pending()

            // error check
            guard self.contactGroup.name != nil else {
                seal.reject(ContactGroupEditError.noNameForGroup)
                return promise
            }

            guard self.contactGroup.emailIDs.count > 0 else {
                seal.reject(ContactGroupEditError.noEmailInGroup)
                return promise
            }

            seal.fulfill(())
            return promise
            }.then {
                _ -> Promise<Void> in
                // perform
                let name = self.contactGroup.name!
                let color = self.contactGroup.color
                let emails = self.contactGroup.emailIDs

                switch self.state {
                case .create:
                    return self.createContactGroupDetail(name: name,
                                                         color: color,
                                                         emailList: emails)
                case .edit:
                    return self.updateContactGroupDetail(name: name,
                                                         color: color,
                                                         updatedEmailList: emails)
                }
        }
    }

    /**
     Returns true if the contact group is modified
     */
    func hasUnsavedChanges() -> Bool {
        return self.contactGroup.hasChanged()
    }

    /**
     Creates the contact group on the server and cache
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     
     - Returns: Promise<Void>
     */
    private func createContactGroupDetail(name: String,
                                          color: String,
                                          emailList: Set<EmailEntity>) -> Promise<Void> {
        let ids = emailList.map { $0.emailID.rawValue }
        return self.contactGroupService.queueCreate(name: name,
                                                    color: color,
                                                    emailIDs: ids)
    }

    /**
     Updates the contact group on the server and cache
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     
     - Returns: Promise<Void>
     */
    private func updateContactGroupDetail(name: String,
                                          color: String,
                                          updatedEmailList: Set<EmailEntity>) -> Promise<Void> {
        let service = self.contactGroupService
        guard let id = self.contactGroup.ID else {
            return Promise.init(error: ContactGroupEditError.TypeCastingError)
        }
        let original = self.contactGroup.originalEmailIDs
        let toAdd = updatedEmailList.subtracting(original)
        let toDelete = original.subtracting(updatedEmailList)

        return service.queueUpdate(groupID: id,
                                   name: name,
                                   color: color,
                                   addedEmailIDs: toAdd.map { $0.emailID.rawValue },
                                   removedEmailIDs: toDelete.map { $0.emailID.rawValue })
    }

    /**
     Deletes the contact group on the server and cache
     
     - Returns: Promise<Void>
     */
    func deleteContactGroup() -> Promise<Void> {
        guard let id = self.contactGroup.ID else {
            return Promise.init(error: ContactGroupEditError.InternalError)
        }
        return self.contactGroupService.queueDelete(groupID: id)
    }

    /* table operation */
    func getTotalSections() -> Int {
        return self.tableContent.count
    }

    func getTotalRows(for section: Int) -> Int {
        guard section < tableContent.count else {
            return 0
        }

        return tableContent[section].count
    }

    func getCellType(at indexPath: IndexPath) -> ContactGroupEditTableCellType {
        guard indexPath.section < tableContent.count &&
            indexPath.row < tableContent[indexPath.section].count else {
                return .error
        }

        return tableContent[indexPath.section][indexPath.row]
    }

    /**
     Returns the email data at the designated indexPath
     
     - Parameter indexPath: the indexPath that is asking for data
     - Returns: a tuple of email name and email address
     */
    func getEmail(at indexPath: IndexPath) -> (EmailID, String, String) {
        guard let data = emailsInGroup[safe: indexPath.row] else {
            return ("", "", "")
        }

        return (data.emailID, data.name, data.email)
    }
}
