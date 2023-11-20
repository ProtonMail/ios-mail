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

import Foundation

struct NewMailSettingsResponse: Decodable {
    let displayName: String
    let signature: String
    let hideEmbeddedImages: Int
    let hideRemoteImages: Int
    let imageProxy: Int
    let autoSaveContacts: Int
    let swipeLeft: Int
    let swipeRight: Int
    let viewMode: Int
    let confirmLink: Int
    let attachPublicKey: Int
    let sign: Int
    let enableFolderColor: Int
    let inheritParentFolderColor: Int
    let delaySendSeconds: Int
    let nextMessageOnMove: Int
    let hideSenderImages: Int
    let showMoved: Int
    let autoDeleteSpamAndTrashDays: Int?
    let almostAllMail: Int
    let mobileSettings: MobileSettings

    enum CodingKeys: String, CodingKey {
        case displayName = "DisplayName"
        case signature = "Signature"
        case hideEmbeddedImages = "HideEmbeddedImages"
        case hideRemoteImages = "HideRemoteImages"
        case imageProxy = "ImageProxy"
        case autoSaveContacts = "AutoSaveContacts"
        case swipeLeft = "SwipeLeft"
        case swipeRight = "SwipeRight"
        case viewMode = "ViewMode"
        case confirmLink = "ConfirmLink"
        case attachPublicKey = "AttachPublicKey"
        case sign = "Sign"
        case enableFolderColor = "EnableFolderColor"
        case inheritParentFolderColor = "InheritParentFolderColor"
        case delaySendSeconds = "DelaySendSeconds"
        case nextMessageOnMove = "NextMessageOnMove"
        case hideSenderImages = "HideSenderImages"
        case showMoved = "ShowMoved"
        case autoDeleteSpamAndTrashDays = "AutoDeleteSpamAndTrashDays"
        case almostAllMail = "AlmostAllMail"
        case mobileSettings = "MobileSettings"
    }

    struct MobileSettings: Decodable {
        let listToolbar: ToolbarActions
        let messageToolbar: ToolbarActions
        let conversationToolbar: ToolbarActions

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case listToolbar = "ListToolbar"
            case messageToolbar = "MessageToolbar"
            case conversationToolbar = "ConversationToolbar"
        }
    }

    struct ToolbarActions: Decodable {
        let isCustom: Bool
        let actions: [String]

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case isCustom = "IsCustom"
            case actions = "Actions"
        }
    }
}
