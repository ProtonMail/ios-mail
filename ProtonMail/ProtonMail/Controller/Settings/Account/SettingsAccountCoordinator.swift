//
//  SettingsAccountCoordinator.swift
//  ProtonMail - Created on 12/12/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

class SettingsAccountCoordinator {
    private let viewModel: SettingsAccountViewModel
    private let services: ServiceFactory

    private weak var navigationController: UINavigationController?

    enum Destination: String {
        case recoveryEmail = "setting_notification"// "recoveryEmail"
        case loginPwd      = "setting_login_pwd"
        case mailboxPwd    = "setting_mailbox_pwd"
        case singlePwd     = "setting_single_password_segue"
        case displayName   = "setting_displayname"
        case signature     = "setting_signature"
        case mobileSignature = "setting_mobile_signature"

//        case notification    = "setting_notification"
//        case debugQueue      = "setting_debug_queue_segue"
//        case pinCode         = "setting_setup_pingcode"
//        case lableManager    = "toManagerLabelsSegue"
//        case loginPwd        = "setting_login_pwd"
//        case mailboxPwd      = "setting_mailbox_pwd"
//        case singlePwd       = "setting_single_password_segue"
//        case snooze          = "setting_notifications_snooze_segue"
        case privacy = "setting_privacy"
        case labels = "labels_management"
        case folders = "folders_management"
        case conversation
    }

    init(navigationController: UINavigationController?, services: ServiceFactory) {
        self.navigationController = navigationController
        self.services = services

        let users: UsersManager = services.get()
        viewModel = SettingsAccountViewModelImpl(user: users.firstUser!)
    }

    func start() {
        let viewController = SettingsAccountViewController(viewModel: self.viewModel, coordinator: self)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func go(to dest: Destination, sender: Any? = nil) {
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
        }
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

}
