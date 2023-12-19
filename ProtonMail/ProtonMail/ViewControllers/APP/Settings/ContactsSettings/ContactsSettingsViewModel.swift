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
    func didTapSetting(_ setting: ContactsSettingsViewModel.Setting, isEnabled: Bool)
}

protocol ContactsSettingsViewModelOutput {
    var settings: [ContactsSettingsViewModel.Setting] { get }

    func value(for setting: ContactsSettingsViewModel.Setting) -> Bool
}

final class ContactsSettingsViewModel: ContactsSettingsViewModelProtocol {
    typealias Dependencies = HasUserDefaults & HasImportDeviceContacts & HasUserManager

    let settings: [Setting] = [.combineContacts, .autoImportContacts]

    enum Cells {
        case combineContacts
        case autoImportContacts
    }

    var input: ContactsSettingsViewModelInput { self }
    var output: ContactsSettingsViewModelOutput { self }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension ContactsSettingsViewModel: ContactsSettingsViewModelOutput {

    func value(for setting: Setting) -> Bool {
        switch setting {
        case .combineContacts:
            return dependencies.userDefaults[.isCombineContactOn]
        case .autoImportContacts:
            return dependencies.userDefaults[.isAutoImportContactsOn]
        }
    }
}

extension ContactsSettingsViewModel: ContactsSettingsViewModelInput {

    func didTapSetting(_ setting: Setting, isEnabled: Bool) {
        switch setting {
        case .combineContacts:
            dependencies.userDefaults[.isCombineContactOn] = isEnabled
        case .autoImportContacts:
            dependencies.userDefaults[.isAutoImportContactsOn] = isEnabled
            if isEnabled {
                let params = ImportDeviceContacts.Params(
                    userKeys: dependencies.user.userInfo.userKeys,
                    mailboxPassphrase: dependencies.user.mailboxPassword
                )
                dependencies.importDeviceContacts.execute(params: params)
            }
        }
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
