// Copyright (c) 2022 Proton Technologies AG
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

import Foundation

protocol LocalizationPreviewUIProtocol: AnyObject {
    func updateTable()
}

final class LocalizationPreviewVM {
    private weak var uiDelegate: LocalizationPreviewUIProtocol?
    private let languages: [ELanguage] = ELanguage.allCases
    private(set) var keys: [String] = []
    private(set) var source: [String: [String]] = [:]

    func setUp(uiDelegate: LocalizationPreviewUIProtocol) {
        self.uiDelegate = uiDelegate
    }

    func prepareData() {
        let currentCode = LanguageManager().currentLanguageCode() ?? "en"
        for lang in languages {
            setUpL11n(for: lang)
        }
        keys = Array(source.keys)
        uiDelegate?.updateTable()
        switchLanguage(to: currentCode)
    }

    func numberOfRowsInSection(section: Int) -> Int {
        source[keys[section]]?.count ?? 0
    }

    func localization(for section: Int, row: Int) -> String? {
        source[keys[section]]?[row]
    }

    func titleForHeader(in section: Int) -> String? {
        keys[section]
    }

    private func switchLanguage(to langCode: String) {
        LanguageManager().saveLanguage(by: langCode)
        LocalizedString.reset()
    }

    private func setUpL11n(for lang: ELanguage) {
        switchLanguage(to: lang.languageCode)
        let allLocalizations = LocalizationList().all
        for (key, value) in allLocalizations {
            let newValues = processPluralIfNeeded(key: key, value: value, code: lang.languageCode).map { "\(lang.languageCode) - \($0)" }
            if source[key] == nil {
                source[key] = newValues
            } else {
                source[key]?.append(contentsOf: newValues)
            }
        }
    }

    private func processPluralIfNeeded(key: String, value: String, code: String) -> [String] {
        let target = [
            "L11n.EmailTrackerProtection.n_email_trackers_blocked",
            "L11n.EmailTrackerProtection.proton_found_n_trackers_on_this_message",
            "LocalizedString._extra_addresses",
            "LocalizedString._mailblox_last_update_time",
            "LocalizedString._general_message",
            "LocalizedString._minute",
            "LocalizedString._general_conversation",
            "LocalizedString._attempt_remaining",
            "LocalizedString._attempt_remaining_until_secure_data_wipe",
            "LocalizedString._hour",
            "LocalizedString._day",
            "LocalizedString._inbox_swipe_to_move_banner_title",
            "LocalizedString._inbox_swipe_to_move_conversation_banner_title",
            "LocalizedString._inbox_swipe_to_label_banner_title",
            "LocalizedString._inbox_swipe_to_label_conversation_banner_title",
            "LocalizedString._clean_message_warning",
            "LocalizedString._clean_conversation_warning",
            "LocalizedString._contact_groups_member_count_description",
            "LocalizedString._scheduled_message_time_in_minute",
            "LocalizedString._delete_scheduled_alert_message",
            "LocalizedString._message_moved_to_drafts",
            "LocalizedString._undo_send_seconds_options",
            "LocalizedString._contact_groups_selected_group_count_description",
            "LocalizedString._attachment",
            "LocalizedString._scheduled_message_time_in_minute"
        ]
        guard target.contains(key) else { return [value] }
        let result = [0, 1, 2].map { String(format: value, $0) }
        return result
    }
}
