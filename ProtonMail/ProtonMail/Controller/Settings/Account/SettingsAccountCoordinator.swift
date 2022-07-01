//
//  SettingsAccountCoordinator.swift
//  Proton Mail - Created on 12/12/18.
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
import ProtonCore_AccountDeletion
import ProtonCore_Networking

class SettingsAccountCoordinator {
    private let viewModel: SettingsAccountViewModel
    private let services: ServiceFactory

    private weak var navigationController: UINavigationController?

    enum Destination: String {
        case recoveryEmail = "setting_notification"
        case loginPwd      = "setting_login_pwd"
        case mailboxPwd    = "setting_mailbox_pwd"
        case singlePwd     = "setting_single_password_segue"
        case displayName   = "setting_displayname"
        case signature     = "setting_signature"
        case mobileSignature = "setting_mobile_signature"
        case privacy = "setting_privacy"
        case labels = "labels_management"
        case folders = "folders_management"
        case conversation = "conversation_mode"
        case undoSend
        case deleteAccount
    }

    init(navigationController: UINavigationController?, services: ServiceFactory) {
        self.navigationController = navigationController
        self.services = services

        let users: UsersManager = services.get()
        viewModel = SettingsAccountViewModelImpl(user: users.firstUser!)
    }

    func start(animated: Bool = false) {
        let viewController = SettingsAccountViewController(viewModel: self.viewModel, coordinator: self)
        self.navigationController?.pushViewController(viewController, animated: animated)
    }

    func go(to dest: Destination) {
        switch dest {
        case .singlePwd:
            openChangePassword(ofType: ChangeSinglePasswordViewModel.self)
        case .loginPwd:
            openChangePassword(ofType: ChangeLoginPWDViewModel.self)
        case .mailboxPwd:
            openChangePassword(ofType: ChangeMailboxPWDViewModel.self)
        case .recoveryEmail:
            openSettingDetail(ofType: ChangeNotificationEmailViewModel.self)
        case .displayName:
            openSettingDetail(ofType: ChangeDisplayNameViewModel.self)
        case .signature:
            openSettingDetail(ofType: ChangeSignatureViewModel.self)
        case .mobileSignature:
            openSettingDetail(ofType: ChangeMobileSignatureViewModel.self)
        case .privacy:
            openPrivacy()
        case .labels:
            openFolderManagement(type: .label)
        case .folders:
            openFolderManagement(type: .folder)
        case .conversation:
            openConversationSettings()
        case .undoSend:
            openUndoSendSettings()
        case .deleteAccount:
            openAccountDeletion()
        }
    }

    func follow(deepLink: DeepLink?) {
        guard let node = deepLink?.popFirst else {
            return
        }
        guard let destination = Destination(rawValue: node.name) else {
            return
        }
        go(to: destination)
    }

    private func openChangePassword<T: ChangePasswordViewModel>(ofType viewModelType: T.Type) {
        let viewModel = T(user: self.viewModel.userManager)
        let cpvc = ChangePasswordViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(cpvc, animated: true)
    }

    private func openSettingDetail<T: SettingDetailsViewModel>(ofType viewModelType: T.Type) {
        let sdvc = SettingDetailViewController(nibName: nil, bundle: nil)
        sdvc.setViewModel(viewModelType.init(user: self.viewModel.userManager))
        self.navigationController?.show(sdvc, sender: nil)
    }

    private func openPrivacy() {
        let coordinator = SettingsPrivacyCoordinator(navigationController: self.navigationController, services: self.services)
        coordinator.start()
    }

    private func openFolderManagement(type: PMLabelType) {
        let vm = LabelManagerViewModel(user: self.viewModel.userManager, type: type)
        let vc = LabelManagerViewController.instance(needNavigation: false)
        let coor = LabelManagerCoordinator(services: self.services,
                                           viewController: vc,
                                           viewModel: vm)
        coor.start()
        self.navigationController?.show(vc, sender: nil)
    }

    private func openConversationSettings() {
        let user = self.viewModel.userManager
        let viewModel = SettingsConversationViewModel(
            conversationStateService: user.conversationStateService,
            updateViewModeService: UpdateViewModeService(apiService: user.apiService),
            eventService: user.eventsService
        )
        let viewController = SettingsConversationViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func openUndoSendSettings() {
        let user = self.viewModel.userManager
        let viewModel = UndoSendSettingViewModel(user: user, delaySeconds: user.userInfo.delaySendSeconds)
        let settingVC = SettingsSingleCheckMarkViewController(viewModel: viewModel)
        viewModel.set(uiDelegate: settingVC)
        self.navigationController?.pushViewController(settingVC, animated: true)
    }
    
    private func openAccountDeletion() {
        let users: UsersManager = services.get()
        guard let user = users.firstUser, let viewController = navigationController?.topViewController as? SettingsAccountViewController else { return }
        viewController.isAccountDeletionPending = true
        let accountDeletion = AccountDeletionService(api: user.apiService)
        accountDeletion.initiateAccountDeletionProcess(over: viewController) { [weak viewController] in
            viewController?.isAccountDeletionPending = false
        } completion: { [weak self] result in
            switch result {
            case .success:
                self?.processSuccessfulAccountDeletion(user: user, users: users)
            case .failure(let error):
                viewController.isAccountDeletionPending = false
                self?.presentAccountDeletionError(error)
            }
        }
    }
    
    private func processSuccessfulAccountDeletion(user: UserManager, users: UsersManager) {
        users.logoutAfterAccountDeletion(user: user)
    }
    
    private func presentAccountDeletionError(_ error: AccountDeletionError) {
        let message: String?
        switch error {
        case .sessionForkingError(let errorMessage):
            message = errorMessage
        case .cannotDeleteYourself(let reason):
            message = reason.networkResponseMessageForTheUser
        case .deletionFailure(let errorMessage):
            message = errorMessage
        case .closedByUser:
            message = nil
        }
        
        guard let message = message else { return }
        
        // TODO: better error presentation
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addCloseAction()
        navigationController?.topViewController?.present(alert, animated: true, completion: nil)
    }
}

extension DeepLink.Node {
    static let conversationMode = DeepLink.Node.init(name: "conversation_mode")
}
