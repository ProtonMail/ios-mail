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

import Factory

extension UserContainer {
    var blockedSenderCacheUpdaterFactory: Factory<BlockedSenderCacheUpdater> {
        self {
            self.user.blockedSenderCacheUpdater
        }
    }

    var blockedSendersPublisherFactory: Factory<BlockedSendersPublisher> {
        self {
            BlockedSendersPublisher(
                contextProvider: sharedServices.get(by: CoreDataService.self),
                userID: self.user.userID
            )
        }
    }

    var unblockSenderFactory: Factory<UnblockSender> {
        self {
            UnblockSender(
                dependencies: .init(
                    incomingDefaultService: self.user.incomingDefaultService,
                    queueManager: self.globalContainer.queueManagerFactory(),
                    userInfo: self.user.userInfo
                )
            )
        }
    }
}
