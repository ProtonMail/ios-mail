// Copyright (c) 2022 Proton AG
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
@testable import ProtonMail
import UserNotifications
import ProtonCore_TestingToolkit

class MockNotificationHandler: NotificationHandler {

    @FuncStub(MockNotificationHandler.add) var callAdd
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        callAdd(request, completionHandler)
    }

    @FuncStub(MockNotificationHandler.removePendingNotificationRequests) var callRemovePendingNoti
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        callRemovePendingNoti(identifiers)
    }

    @FuncStub(MockNotificationHandler.getPendingNotificationRequests) var callGetPendingReqs
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        callGetPendingReqs(completionHandler)
    }

    @FuncStub(MockNotificationHandler.getDeliveredNotifications) var callGetDelivered
    func getDeliveredNotifications(completionHandler: @escaping ([UNNotification]) -> Void) {
        callGetDelivered(completionHandler)
    }

    @FuncStub(MockNotificationHandler.removeDeliveredNotifications) var callRemoveDelivered
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        callRemoveDelivered(identifiers)
    }
}
