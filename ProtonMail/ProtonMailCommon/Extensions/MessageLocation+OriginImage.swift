// swiftlint:disable:this file_name
//
//  MessageLocation+OriginImage.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

extension Message.Location {

    func originImage(viewMode: ViewMode = .singleMessage) -> UIImage? {
        switch self {
        case .archive:
            return Asset.mailArchiveIcon.image
        case .draft:
            return viewMode.originImage
        case .sent:
            return Asset.mailSendIcon.image
        case .spam:
            return Asset.mailSpamIcon.image
        case .trash:
            return Asset.mailTrashIcon.image
        case .inbox:
            return Asset.mailInboxIcon.image
        case .starred, .allmail:
            return nil
        }
    }

}

private extension ViewMode {

    var originImage: UIImage {
        switch self {
        case .singleMessage:
            return Asset.mailDraftIcon.image
        case .conversation:
            return Asset.mailConversationDraft.image
        }
    }

}
