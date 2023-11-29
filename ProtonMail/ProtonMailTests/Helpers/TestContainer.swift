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
import ProtonCoreKeymaker

@testable import ProtonMail

class TestContainer: GlobalContainer {
    private let uuid = UUID()

    override init() {
        super.init()

        contextProviderFactory.register {
            MockCoreDataContextProvider()
        }

        keychainFactory.register {
            Keychain(service: "ch.protonmail.test.\(self.uuid)", accessGroup: "2SB5Z68H26.ch.protonmail.protonmail")
        }

        notificationCenterFactory.register {
            NotificationCenter()
        }

        queueManagerFactory.register {
            let messageQueue = PMPersistentQueue(queueName: "message.\(self.uuid)")
            let miscQueue = PMPersistentQueue(queueName: "misc.\(self.uuid)")
            return QueueManager(messageQueue: messageQueue, miscQueue: miscQueue)
        }

        userDefaultsFactory.register {
            .init(suiteName: "ch.protonmail.test.\(self.uuid)")!
        }
    }
}
