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

import ProtonCoreAccountDeletion
import ProtonCoreAccountRecovery
import ProtonCoreDataModel
import ProtonCoreLog
import ProtonCoreLoginUI
import ProtonCoreNetworking
import ProtonCorePasswordChange
import ProtonCoreFeatureFlags
import ProtonMailUI
import UIKit

// sourcery: mock
protocol SettingsAccountCoordinatorProtocol: AnyObject {
    func go(to dest: SettingsAccountCoordinator.Destination)
}

class SettingsAccountCoordinator: SettingsAccountCoordinatorProtocol {
    typealias Dependencies = BlockedSendersViewModel.Dependencies
    & LabelManagerRouter.Dependencies
    & HasKeychain
    & HasKeyMakerProtocol
    & HasUsersManager
    & HasAPIService

    private let viewModel: SettingsAccountViewModel
    private let users: UsersManager
    private let dependencies: Dependencies
    @MainActor private var upsellCoordinator: UpsellCoordinator?

    private var user: UserManager {
        users.firstUser!
    }

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
        case nextMsgAfterMove
        case blockList
        case autoDeleteSpamTrash
        case privacyAndData
        case accountRecovery
        case securityKeys
    }

    init(navigationController: UINavigationController?, dependencies: Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
        users = dependencies.usersManager
        let firstUser = users.firstUser!
        viewModel = SettingsAccountViewModel(
            user: firstUser,
            isMessageSwipeNavigationEnabled: firstUser.isMessageSwipeNavigationSettingEnabled
        )
    }

    func start(animated: Bool = false) {
        let viewController = SettingsAccountViewController(viewModel: self.viewModel, coordinator: self)
        self.navigationController?.pushViewController(viewController, animated: animated)
    }

    func go(to dest: Destination) {
        switch dest {
        case .blockList:
            openBlockList()
        case .singlePwd:
            openCoreChangePassword(mode: .singlePassword)
        case .loginPwd:
            openCoreChangePassword(mode: .loginPassword)
        case .mailboxPwd:
            openCoreChangePassword(mode: .mailboxPassword)
        case .recoveryEmail:
            openSettingDetail(ofType: ChangeNotificationEmailViewModel.self)
        case .displayName:
            openSettingDetail(ofType: ChangeDisplayNameViewModel.self)
        case .signature:
            openSettingDetail(ofType: ChangeSignatureViewModel.self)
        case .mobileSignature:
            if user.hasPaidMailPlan {
                openSettingDetail(ofType: ChangeMobileSignatureViewModel.self)
            } else {
                presentUpsellView(entryPoint: .mobileSignature)
            }
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
        case .nextMsgAfterMove:
            openNextMessageAfterMove()
        case .autoDeleteSpamTrash:
            if user.hasPaidMailPlan {
                openAutoDeleteSettings()
            } else {
                presentUpsellView(entryPoint: .autoDelete)
            }
        case .privacyAndData:
            openPrivacyAndDataSetting()
        case .accountRecovery:
            openAccountRecovery()
        case .securityKeys:
            openSecurityKeys()
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

    private func openBlockList() {
        let viewModel = BlockedSendersViewModel(dependencies: dependencies)
        let viewController = BlockedSendersViewController(viewModel: viewModel)
        navigationController?.show(viewController, sender: nil)
    }

    private func openCoreChangePassword(mode: PasswordChangeModule.PasswordChangeMode) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let viewController = PasswordChangeModule.makePasswordChangeViewController(
                mode: mode,
                apiService: dependencies.apiService,
                authCredential: user.authCredential,
                userInfo: user.userInfo,
                completion: processSuccessfulPasswordChange
            )
            self.navigationController?.show(viewController, sender: true)
        }
    }

    private func processSuccessfulPasswordChange(authCredential: AuthCredential, userInfo: UserInfo) {
        user.update(userInfo: userInfo)
        user.update(authCredential: authCredential)
        self.navigationController?.popToRootViewController(animated: true)
        L10n.Settings.passwordUpdated.alertToast(withTitle: false)
    }

    private func openSettingDetail<T: SettingDetailsViewModel>(ofType viewModelType: T.Type) {
        let viewModel = viewModelType.init(user: user, coreKeyMaker: dependencies.keyMaker)
        let sdvc = SettingDetailViewController(viewModel: viewModel)
        self.navigationController?.show(sdvc, sender: nil)
    }

    private func openPrivacy() {
        let viewModel = PrivacySettingViewModel(user: user, keychain: dependencies.keychain)
        let viewController = SwitchToggleViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openFolderManagement(type: PMLabelType) {
        guard let navigationController = navigationController else { return }
        let router = LabelManagerRouter(dependencies: dependencies, navigationController: navigationController)
        let dependencies = LabelManagerViewModel.Dependencies(userManager: user)
        let viewModel = LabelManagerViewModel(router: router, type: type, dependencies: dependencies)
        let vc = LabelManagerViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }

    private func openConversationSettings() {
        let viewModel = ConversationSettingViewModel(
            updateViewModeService: UpdateViewModeService(apiService: user.apiService),
            conversationStateService: user.conversationStateService,
            eventService: user.eventsService
        )
        let viewController = SwitchToggleViewController(viewModel: viewModel)
        navigationController?.show(viewController, sender: nil)
    }

    private func openUndoSendSettings() {
        let viewModel = UndoSendSettingViewModel(user: user, delaySeconds: user.userInfo.delaySendSeconds)
        let settingVC = SettingsSingleCheckMarkViewController(viewModel: viewModel)
        viewModel.set(uiDelegate: settingVC)
        self.navigationController?.pushViewController(settingVC, animated: true)
    }

    private func openAutoDeleteSettings() {
        let viewModel = AutoDeleteSettingViewModel(user, apiService: user.apiService)
        let viewController = SwitchToggleViewController(viewModel: viewModel)
        navigationController?.show(viewController, sender: nil)
    }
    
    private func openAccountDeletion() {
        guard let viewController = navigationController?.topViewController as? SettingsAccountViewController else {
            return
        }

        viewController.isAccountDeletionPending = true
        let accountDeletion = AccountDeletionService(api: user.apiService)
        accountDeletion.initiateAccountDeletionProcess(
            over: viewController,
            performBeforeClosingAccountDeletionScreen: { [weak viewController] completion in
                viewController?.isAccountDeletionPending = false
                completion()
            },
            completion: { [weak self] result in
                switch result {
                case .success:
                    self?.processSuccessfulAccountDeletion()
                case .failure(let error):
                    viewController.isAccountDeletionPending = false
                    self?.presentAccountDeletionError(error)
                }
            }
        )
    }
    
    private func processSuccessfulAccountDeletion() {
        users.logoutAfterAccountDeletion(user: user)
    }
    
    private func presentAccountDeletionError(_ error: AccountDeletionError) {
        let message: String?
        switch error {
        case let .apiMightBeBlocked(errorMessage, originalError):
            PMLog.error(originalError)
            message = errorMessage
        case .sessionForkingError(let errorMessage):
            message = errorMessage
        case .cannotDeleteYourself(let reason):
            message = reason.localizedDescription
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

    private func openNextMessageAfterMove() {
        let viewModel = NextMessageAfterMoveViewModel(user, apiService: user.apiService)
        let viewController = SwitchToggleViewController(viewModel: viewModel)
        navigationController?.show(viewController, sender: nil)
    }

    private func presentUpsellView(entryPoint: UpsellPageEntryPoint) {
        Task { @MainActor in
            guard let navigationController else {
                return
            }

            upsellCoordinator = dependencies.paymentsUIFactory.makeUpsellCoordinator(rootViewController: navigationController)
            upsellCoordinator?.start(entryPoint: entryPoint)
        }
    }

    private func openPrivacyAndDataSetting() {
        let viewModel = PrivacyAndDataSettingViewModel(dependencies: user.container)
        let viewController = SwitchToggleViewController(viewModel: viewModel)
        navigationController?.show(viewController, sender: nil)
	}

    private func openAccountRecovery() {
        let accountRecoveryVC = AccountRecoveryModule.settingsViewController(user.apiService) { [weak self] newAccountRecovery in
            self?.user.userInfo.accountRecovery = newAccountRecovery
        }
        navigationController?.show(accountRecoveryVC, sender: nil)
    }

    private func openSecurityKeys() {
        let securityKeysVC = LoginUIModule.makeSecurityKeysViewController(apiService: user.apiService, clientApp: .mail)
        navigationController?.show(securityKeysVC, sender: nil)
    }
}
