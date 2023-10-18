//
//  ContactGroupDetailViewModel.swift
//  Proton Mail - Created on 2018/9/10.
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

import CoreData
import Foundation
import PromiseKit

protocol ContactGroupDetailVMProtocol {
    var reloadView: (() -> Void)? { get set }
    var dismissView: (() -> Void)? { get set }

    var user: UserManager { get }
    var groupID: LabelID { get }
    var name: String { get }
    var color: String { get }
    var emails: [EmailEntity] { get }

    func getTotalEmailString() -> String
}

final class ContactGroupDetailViewModel: NSObject, ContactGroupDetailVMProtocol {
    typealias Dependencies = HasUserManager & HasCoreDataContextProviderProtocol

    private var contactGroup: LabelEntity
    /// the contact group label ID
    var groupID: LabelID { self.contactGroup.labelID }
    var name: String { self.contactGroup.name }
    var color: String { self.contactGroup.color }
    private(set) var emails: [EmailEntity] = []

    var user: UserManager {
        dependencies.user
    }

    private let labelPublisher: LabelPublisher
    private let dependencies: Dependencies

    var reloadView: (() -> Void)?
    var dismissView: (() -> Void)?

    init(contactGroup: LabelEntity, dependencies: Dependencies) {
        self.dependencies = dependencies
        self.contactGroup = contactGroup
        labelPublisher = .init(
            parameters: .init(userID: dependencies.user.userID),
            dependencies: dependencies
        )

        super.init()
        self.sortEmails(emailArray: contactGroup.emailRelations)
        labelPublisher.delegate = self
        labelPublisher.fetchLabel(contactGroup.labelID)
    }

    private func sortEmails(emailArray: [EmailEntity]) {
        self.emails = emailArray.sorted { first, second in
            if first.name == second.name {
                return first.email < second.email
            }
            return first.name < second.name
        }
    }

    func getTotalEmailString() -> String {
        let count = self.emails.count
        return String(format: LocalString._contact_groups_member_count_description, count)
    }
}

extension ContactGroupDetailViewModel: LabelListenerProtocol {
    func receivedLabels(labels: [LabelEntity]) {
        guard let label = labels.first else {
            dismissView?()
            return
        }
        guard label != contactGroup else {
            return
        }
        contactGroup = label
        sortEmails(emailArray: label.emailRelations)
        reloadView?()
    }
}
