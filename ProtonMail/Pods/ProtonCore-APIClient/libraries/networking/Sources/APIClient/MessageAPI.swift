//
//  MessageAPI.swift
//  ProtonCore-APIClient - Created on 5/22/20.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

// swiftlint:disable identifier_name

import Foundation

class MessageAPI: APIClient {

    static let route: String = "/messages"

    // Get a list of message metadata [GET]
    static let v_fetch_messages: Int = 3

    // Get grouped message count [GET]
    static let v_message_count: Int = 3

    static let v_create_draft: Int = 3

    static let v_update_draft: Int = 3

    // inlcude read/unread
    static let V_MessageActionRequest: Int = 3

    // Send a message [POST]
    static let v_send_message: Int = 3

    // Label/move an array of messages [PUT]
    static let v_label_move_msgs: Int = 3

    // Unlabel an array of messages [PUT]
    static let v_unlabel_msgs: Int = 3

    // Delete all messages with a label/folder [DELETE]
    static let v_empty_label_folder: Int = 3

    // Delete an array of messages [PUT]
    static let v_delete_msgs: Int = 3

    // Undelete Messages [/messages/undelete]
    static let v_undelete_msgs: Int = 3

    // Label/Move Messages [/messages/label] [PUT]
    static let v_apply_label_to_messages: Int = 3

    // Unlabel Messages [/messages/unlabel] [PUT]
    static let v_remove_label_from_message: Int = 3
}
