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
import ProtonCore_DataModel

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
    case darkMode = 0
    case appPIN
    case swipeAction
    case combinContacts
    case alternativeRouting
    case browser

    public var description: String {
        switch self {
        case .darkMode:
            return LocalString._dark_mode
        case .appPIN:
            return LocalString._app_pin
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
    var isDohOn: Bool { get }

    var appPINTitle: String { get }

    func cleanCache(completion: ((Result<Void, NSError>) -> Void)?)
}

class SettingsDeviceViewModelImpl : SettingsDeviceViewModel {

    var sections: [SettingDeviceSection] = [ .account, .app, .general, .clearCache]
    
    var appSettigns: [DeviceSectionItem] = [.appPIN, .combinContacts, .browser, .alternativeRouting, .swipeAction]

    var generalSettings: [GeneralSectionItem] = [.notification, .language]

    private(set) var userManager: UserManager
    private let users: UsersManager
    private let dohSetting: DohStatusProtocol
    private let biometricStatus: BiometricStatusProvider

    var lockOn: Bool {
        return userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled
    }

    var combineContactOn: Bool {
        return userCachedStatus.isCombineContactOn
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

    var appPINTitle: String {
        switch biometricStatus.biometricType {
        case .faceID:
            return LocalString._app_pin_with_faceid
        case .touchID:
            return LocalString._app_pin_with_touchid
        default:
            return LocalString._app_pin
        }
    }

    init(user: UserManager, users: UsersManager, dohSetting: DohStatusProtocol, biometricStatus: BiometricStatusProvider) {
        self.userManager = user
        self.users = users
        self.dohSetting = dohSetting
        self.biometricStatus = biometricStatus
        if #available(iOS 13, *), UserInfo.isDarkModeEnable {
            appSettigns.insert(.darkMode, at: 0)
        }
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
