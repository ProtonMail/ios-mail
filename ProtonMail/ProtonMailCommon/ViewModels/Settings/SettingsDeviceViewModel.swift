//
//  SettingsViewModel.swift
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

import Foundation

public enum SettingDeviceSection: Int, CustomStringConvertible {
    case account = 0
    case app = 1
    case general = 2
    case clearCache = 3

    public var description: String {
        switch self {
        case .account:
            return LocalString._account_settings
        case .app:
            return LocalString._app_settings
        case .general:
            return LocalString._app_general_settings
        case .clearCache:
            return ""
        }
    }
}

public enum DeviceSectionItem: Int, CustomStringConvertible {
    case autolock = 0
    case swipeAction = 1
    case combinContacts = 2
    case alternativeRouting = 3
    case browser = 4

    public var description: String {
        switch self {
        case .autolock:
            return LocalString._auto_lock
        case .combinContacts:
            return LocalString._combined_contacts
        case .browser:
            return LocalString._default_browser
        case .swipeAction:
            return LocalString._swipe_actions
        case .alternativeRouting:
            return LocalString._alternative_routing
        }
    }
}

public enum GeneralSectionItem: Int, CustomStringConvertible {
    case notification = 0
    case language = 1

    public var description: String {
        switch self {
        case .notification:
            return LocalString._push_notification
        case .language:
            return LocalString._app_language
        }
    }
}

protocol SettingsDeviceViewModel: AnyObject {
    var sections: [SettingDeviceSection] { get set }

    var appSettigns: [DeviceSectionItem] { get set }

    var generalSettings: [GeneralSectionItem] { get set }
    
    func appVersion() -> String

    var userManager: UserManager { get }

    var email: String { get }
    var name: String { get }

    var languages: [ELanguage] { get }

    var lockOn: Bool { get }
    var combineContactOn: Bool { get }
    var biometricType: BiometricType { get }
    var isDohOn: Bool { get }

    func cleanCache(completion: ((Result<Void, NSError>) -> Void)?)
}

class SettingsDeviceViewModelImpl : SettingsDeviceViewModel {
    var sections: [SettingDeviceSection] = [ .account, .app, .general, .clearCache]
    
    var appSettigns: [DeviceSectionItem] = [.autolock, .combinContacts, .browser, .alternativeRouting, .swipeAction]

    var generalSettings: [GeneralSectionItem] = [.notification, .language]

    var userManager: UserManager
    private let users: UsersManager
    private let bioStatusProvider: BiometricStatusProvider
    private var dohSetting: DohStatusProtocol

    var lockOn: Bool {
        return userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled
    }

    var combineContactOn: Bool {
        return userCachedStatus.isCombineContactOn
    }

    var biometricType: BiometricType {
        return self.bioStatusProvider.biometricType
    }

    var email: String {
        return self.userManager.defaultEmail
    }

    var name: String {
        let name = self.userManager.defaultDisplayName
        return name.isEmpty ? self.email : name
    }

    var languages: [ELanguage] = ELanguage.allItems()

    var isDohOn: Bool {
        return self.dohSetting.status == .on
    }

    init(user: UserManager, users: UsersManager, bioStatusProvider: BiometricStatusProvider, dohSetting: DohStatusProtocol) {
        self.userManager = user
        self.users = users
        self.bioStatusProvider = bioStatusProvider
        self.dohSetting = dohSetting
    }

    func appVersion() -> String {
        var appVersion = "Unkonw Version"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = "\(version)"
        }
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = appVersion + " (\(build))"
        }
        return appVersion
    }

    func cleanCache(completion: ((Result<Void, NSError>) -> Void)?) {
        for user in users.users {
            user.messageService.cleanLocalMessageCache { (_, _, error) in
                user.conversationService.cleanAll()
                user.conversationService.fetchConversations(for: Message.Location.inbox.rawValue,
                                                            before: 0,
                                                            unreadOnly: false,
                                                            shouldReset: false) { result in
                    if user.userinfo.userId == self.userManager.userinfo.userId {
                        switch result {
                        case .failure(let error):
                            completion?(.failure(error as NSError))
                        case .success(_):
                            completion?(.success(()))
                        }
                    }
                }
            }
        }
    }
}
