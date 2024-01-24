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

import Combine

protocol ContactsSettingsViewModelProtocol {
    var input: ContactsSettingsViewModelInput { get }
    var output: ContactsSettingsViewModelOutput { get }
}

protocol ContactsSettingsViewModelInput {
    func requestContactAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func didTapSetting(_ setting: ContactsSettingsViewModel.Setting, isEnabled: Bool)
}

protocol ContactsSettingsViewModelOutput {
    var settings: [ContactsSettingsViewModel.Setting] { get }
    var isContactAccessDenied: Bool { get }

    func value(for setting: ContactsSettingsViewModel.Setting) -> Bool
}

final class ContactsSettingsViewModel: ContactsSettingsViewModelProtocol {
    typealias Dependencies = HasUserDefaults & HasImportDeviceContacts & HasUserManager

    let settings: [Setting] = [.combineContacts, .autoImportContacts]

    var input: ContactsSettingsViewModelInput { self }
    var output: ContactsSettingsViewModelOutput { self }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension ContactsSettingsViewModel: ContactsSettingsViewModelOutput {

    var isContactAccessDenied: Bool {
        [.denied, .restricted].contains(CNContactStore.authorizationStatus(for: .contacts))
    }

    func value(for setting: Setting) -> Bool {
        switch setting {
        case .combineContacts:
            return dependencies.userDefaults[.isCombineContactOn]
        case .autoImportContacts:
            let autoImportFlags = dependencies.userDefaults[.isAutoImportContactsOn]
            return autoImportFlags[dependencies.user.userID.rawValue] ?? false
        }
    }
}

extension ContactsSettingsViewModel: ContactsSettingsViewModelInput {

    func requestContactAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        CNContactStore().requestAccess(for: .contacts, completionHandler: completion)
    }

    func didTapSetting(_ setting: Setting, isEnabled: Bool) {
        switch setting {
        case .combineContacts:
            dependencies.userDefaults[.isCombineContactOn] = isEnabled
        case .autoImportContacts:
            didTapAutoImportContacts(isEnabled: isEnabled)
        }
    }

    private func didTapAutoImportContacts(isEnabled: Bool) {
        var autoImportFlags = dependencies.userDefaults[.isAutoImportContactsOn]
        autoImportFlags[dependencies.user.userID.rawValue] = isEnabled
        dependencies.userDefaults[.isAutoImportContactsOn] = autoImportFlags
        if isEnabled {
            let params = ImportDeviceContacts.Params(
                userKeys: dependencies.user.userInfo.userKeys,
                mailboxPassphrase: dependencies.user.mailboxPassword
            )
            dependencies.importDeviceContacts.execute(params: params)
        } else {
            var historyTokens = dependencies.userDefaults[.contactsHistoryTokenPerUser]
            historyTokens[dependencies.user.userID.rawValue] = nil
            dependencies.userDefaults[.contactsHistoryTokenPerUser] = historyTokens
        }
        let msg = "Auto import contacts changed to: \(isEnabled) for user \(dependencies.user.userID.rawValue.redacted)"
        SystemLogger.log(message: msg, category: .contacts)
    }
}

extension ContactsSettingsViewModel {
    enum Setting {
        case combineContacts
        case autoImportContacts

        var title: String {
            switch self {
            case .combineContacts:
                L11n.SettingsContacts.combinedContacts
            case .autoImportContacts:
                L11n.SettingsContacts.autoImportContacts
            }
        }

        var footer: String {
            switch self {
            case .combineContacts:
                L11n.SettingsContacts.combinedContactsFooter
            case .autoImportContacts:
                L11n.SettingsContacts.autoImportContactsFooter
            }
        }
    }
}
