//
//  MailListActionSheetViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

struct MailListActionSheetViewModel {
    let title: String
    private(set) var items: [MailListActionSheetItemViewModel] = []

    init(labelId: String, title: String) {
        self.title = title

        items += [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel()
        ]

        if labelId == Message.Location.trash.rawValue {
            items += [.moveToInboxActionViewModel()]
        } else {
            items += [.removeActionViewModel()]
        }

        if labelId == Message.Location.archive.rawValue {
            items += [.moveToInboxActionViewModel()]
        } else if labelId == Message.Location.spam.rawValue {
            items += [.notSpamActionViewModel()]
        } else {
            items += [.moveToArchive()]
        }

        let locationsHavingSpam: [Message.Location] = [.draft, .spam, .sent, .trash]
        if let location = Message.Location(rawValue: labelId), locationsHavingSpam.contains(location) {
            items += [.deleteActionViewModel()]
        } else {
            items += [.moveToSpam()]
        }
        items += [.moveToActionViewModel()]
    }
}
