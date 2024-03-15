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

import ProtonCoreUtilities

final class ContactViewsFactory {
    typealias Dependencies = AnyObject
    & ContactEditViewController.Dependencies
    & ContactGroupDetailViewController.Dependencies
    & HasInternetConnectionStatusProviderProtocol
    & ContactGroupSelectEmailViewModelImpl.Dependencies
    & ContactImportViewController.Dependencies
    & ContactsViewModel.Dependencies
    & HasAutoImportContactsFeature
    & HasImportDeviceContacts

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func makeContactsView() -> ContactsViewController {
        let contactsViewModel = ContactsViewModel(dependencies: dependencies)
        return ContactsViewController(viewModel: contactsViewModel, dependencies: dependencies)
    }

    func makeTypeView(type: ContactEditTypeInterface) -> ContactTypeViewController {
        let viewModel = ContactTypeViewModelImpl(t: type)
        return ContactTypeViewController(viewModel: viewModel)
    }

    func makeDetailView(contact: ContactEntity) -> ContactDetailViewController {
        let viewModel = ContactDetailsViewModel(
            contact: contact,
            dependencies: .init(
                user: dependencies.user,
                coreDataService: dependencies.contextProvider,
                contactService: dependencies.user.contactService
            )
        )
        return ContactDetailViewController(viewModel: viewModel, dependencies: dependencies)
    }

    func makeEditView(contact: ContactEntity?) -> ContactEditViewController {
        makeEditView(contact: contact.map { .left($0) })
    }

    func makeEditView(contact: ContactVO) -> ContactEditViewController {
        makeEditView(contact: .right(contact))
    }

    private func makeEditView(contact: Either<ContactEntity, ContactVO>?) -> ContactEditViewController {
        let viewModelDependencies = ContactEditViewModel.Dependencies(
            user: dependencies.user,
            contextProvider: dependencies.contextProvider,
            contactService: dependencies.user.contactService
        )

        let viewModel: ContactEditViewModel
        switch contact {
        case .left(let contactEntity):
            viewModel = ContactEditViewModel(contactEntity: contactEntity, dependencies: viewModelDependencies)
        case .right(let contactVO):
            viewModel = ContactEditViewModel(contactVO: contactVO, dependencies: viewModelDependencies)
        case .none:
            viewModel = ContactEditViewModel(contactEntity: nil, dependencies: viewModelDependencies)
        }

        return ContactEditViewController(viewModel: viewModel, dependencies: dependencies)
    }

    func makeGroupEditView(
        state: ContactGroupEditViewControllerState,
        groupID: String?,
        name: String?,
        color: String?,
        emailIDs: Set<EmailEntity>
    ) -> ContactGroupEditViewController {
        let viewModel = ContactGroupEditViewModelImpl(
            state: state,
            user: dependencies.user,
            groupID: groupID,
            name: name,
            color: color,
            emailIDs: emailIDs
        )
        return ContactGroupEditViewController(viewModel: viewModel, dependencies: dependencies)
    }

    func makeGroupSelectColorView(
        currentColor: String,
        refreshHandler: @escaping (String) -> Void
    ) -> ContactGroupSelectColorViewController {
        let viewModel = ContactGroupSelectColorViewModelImpl(
            currentColor: currentColor,
            refreshHandler: refreshHandler
        )
        return ContactGroupSelectColorViewController(viewModel: viewModel)
    }

    func makeGroupSelectEmailView(
        selectedEmails: Set<EmailEntity>,
        refreshHandler: @escaping (Set<EmailEntity>) -> Void
    ) -> ContactGroupSelectEmailViewController {
        let viewModel = ContactGroupSelectEmailViewModelImpl(
            selectedEmails: selectedEmails,
            dependencies: dependencies,
            refreshHandler: refreshHandler
        )
        return ContactGroupSelectEmailViewController(viewModel: viewModel)
    }

    func makeGroupsView() -> ContactGroupsViewController {
        let contactGroupViewModel = ContactGroupsViewModelImpl(dependencies: dependencies)
        return ContactGroupsViewController(viewModel: contactGroupViewModel, dependencies: dependencies)
    }

    func makeGroupMutiSelectView(
        groupCountInformation: [(ID: String, name: String, color: String, count: Int)]? = nil,
        selectedGroupIDs: Set<String>? = nil,
        refreshHandler: (@escaping (Set<String>) -> Void)
    ) -> ContactGroupsViewController {
        let viewModel = ContactGroupMutiSelectViewModelImpl(
            user: dependencies.user,
            groupCountInformation: groupCountInformation,
            selectedGroupIDs: selectedGroupIDs,
            refreshHandler: refreshHandler
        )
        return ContactGroupsViewController(viewModel: viewModel, dependencies: dependencies)
    }

    func makeGroupDetailView(label: LabelEntity) -> ContactGroupDetailViewController {
        let viewModel = ContactGroupDetailViewModel(
            contactGroup: label,
            dependencies: dependencies
        )
        return ContactGroupDetailViewController(viewModel: viewModel, dependencies: dependencies)
    }

    func makeImportView() -> ContactImportViewController {
        ContactImportViewController(dependencies: dependencies)
    }
}
