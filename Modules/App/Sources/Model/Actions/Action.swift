// Copyright (c) 2024 Proton Technologies AG
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

import DeveloperToolsSupport
import Foundation
import InboxDesignSystem
import SwiftUI

/**
 List of all the actions that can take place over a message or a conversation.

 The purpose of this enum is to declare icons and strings related to an action only once.
 */
enum Action: ActionPickerListElement {
    case deletePermanently
    case markAsRead
    case markAsUnread
    case labelAs
    case moveTo
    case moveToArchive
    case moveToInbox
    case moveToInboxFromSpam
    case moveToSpam
    case moveToTrash
    case pin
    case print
    case renderInLightMode
    case reportPhishing
    case saveAsPDF
    case star
    case snooze
    case unpin
    case unstar
    case viewHeaders
    case viewHTML

    var name: LocalizedStringResource {
        L10n.Action.self[keyPath: nameKeyPath]
    }

    private var nameKeyPath: KeyPath<L10n.Action.Type, LocalizedStringResource> {
        switch self {
        case .deletePermanently: \.deletePermanently
        case .markAsRead: \.markAsRead
        case .markAsUnread: \.markAsUnread
        case .labelAs: \.labelAs
        case .moveTo: \.moveTo
        case .moveToArchive: \.moveToArchive
        case .moveToInbox: \.moveToInbox
        case .moveToInboxFromSpam: \.moveToInboxFromSpam
        case .moveToSpam: \.moveToSpam
        case .moveToTrash: \.moveToTrash
        case .pin: \.pin
        case .print: \.print
        case .renderInLightMode: \.renderInLightMode
        case .reportPhishing: \.reportPhishing
        case .saveAsPDF: \.saveAsPDF
        case .star: \.star
        case .snooze: \.snooze
        case .unpin: \.unpin
        case .unstar: \.unstar
        case .viewHeaders: \.viewHeaders
        case .viewHTML: \.viewHTML
        }
    }

    var icon: Image {
        switch self {
        case .deletePermanently:
            DS.Icon.icTrashCross.image
        case .labelAs:
            DS.Icon.icTag.image
        case .markAsRead:
            DS.Icon.icEnvelopeOpen.image
        case .markAsUnread:
            DS.Icon.icEnvelopeDot.image
        case .moveTo:
            DS.Icon.icFolderArrowIn.image
        case .moveToArchive:
            DS.Icon.icArchiveBox.image
        case .moveToInbox:
            DS.Icon.icInbox.image
        case .moveToInboxFromSpam:
            DS.Icon.icNotSpam.image
        case .moveToSpam:
            DS.Icon.icSpam.image
        case .moveToTrash:
            DS.Icon.icTrash.image
        case .pin:
            DS.Icon.icPinAngled.image
        case .print:
            DS.Icon.icPrinter.image
        case .renderInLightMode:
            DS.Icon.icSun.image
        case .reportPhishing:
            DS.Icon.icHook.image
        case .saveAsPDF:
            DS.Icon.icFilePDF.image
        case .snooze:
            DS.Icon.icClock.image
        case .star:
            Image(systemName: DS.SFSymbols.star)
        case .unpin:
            DS.Icon.icPinAngledSlash.image
        case .unstar:
            Image(systemName: DS.SFSymbols.starSlash)
        case .viewHeaders:
            DS.Icon.icFileLines.image
        case .viewHTML:
            DS.Icon.icCode.image
        }
    }
}
