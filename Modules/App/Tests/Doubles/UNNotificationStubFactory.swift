// Copyright (c) 2025 Proton Technologies AG
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

import UserNotifications

/// This factory allows for instantiating several UserNotification classes for unit testing purposes, as they do not expose feasible initializers
enum UNNotificationResponseStubFactory {
    static func makeNotification(identifier: String? = nil, content: UNNotificationContent) -> UNNotification {
        let request = class_createInstance(UNNotificationRequestStub.self, 0) as! UNNotificationRequestStub
        request._content = content
        request._identifier = identifier

        let notification = class_createInstance(UNNotificationStub.self, 0) as! UNNotificationStub
        notification._request = request
        return notification
    }

    static func makeResponse(actionIdentifier: String, content: UNNotificationContent) -> UNNotificationResponse {
        let response = class_createInstance(UNNotificationResponseStub.self, 0) as! UNNotificationResponseStub
        response._actionIdentifier = actionIdentifier
        response._notification = makeNotification(content: content)
        return response
    }
}

private class UNNotificationResponseStub: UNNotificationResponse {
    var _actionIdentifier: String?
    var _notification: UNNotification?

    override var notification: UNNotification {
        _notification ?? super.notification
    }

    override var actionIdentifier: String {
        _actionIdentifier ?? super.actionIdentifier
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class UNNotificationStub: UNNotification {
    var _request: UNNotificationRequest?

    override var request: UNNotificationRequest {
        _request ?? super.request
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class UNNotificationRequestStub: UNNotificationRequest {
    var _content: UNNotificationContent?
    var _identifier: String?

    override var content: UNNotificationContent {
        _content ?? super.content
    }

    override var identifier: String {
        _identifier ?? super.identifier
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
