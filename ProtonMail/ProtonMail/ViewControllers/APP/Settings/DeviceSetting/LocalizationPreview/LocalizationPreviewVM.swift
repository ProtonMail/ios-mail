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
            "LocalString._extra_addresses",
            "LocalString._mailblox_last_update_time",
            "LocalString._general_message",
            "LocalString._minute",
            "LocalString._general_conversation",
            "LocalString._attempt_remaining",
            "LocalString._attempt_remaining_until_secure_data_wipe",
            "LocalString._hour",
            "LocalString._day",
            "LocalString._inbox_swipe_to_move_banner_title",
            "LocalString._inbox_swipe_to_move_conversation_banner_title",
            "LocalString._inbox_swipe_to_label_banner_title",
            "LocalString._inbox_swipe_to_label_conversation_banner_title",
            "LocalString._clean_message_warning",
            "LocalString._clean_conversation_warning",
            "LocalString._contact_groups_member_count_description",
            "LocalString._scheduled_message_time_in_minute",
            "LocalString._delete_scheduled_alert_message",
            "LocalString._message_moved_to_drafts",
            "LocalString._undo_send_seconds_options",
            "LocalString._contact_groups_selected_group_count_description",
            "LocalString._attachment",
            "LocalString._scheduled_message_time_in_minute"
        ]
        guard target.contains(key) else { return [value] }
        let result = [0, 1, 2].map { String(format: value, $0) }
        return result
    }
}
