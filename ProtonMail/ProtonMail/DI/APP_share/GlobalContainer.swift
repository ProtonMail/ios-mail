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
import ProtonCore_Keymaker

final class GlobalContainer: ManagedContainer {
    let manager = ContainerManager()

    var attachmentMetadataStripStatusProviderFactory: Factory<AttachmentMetadataStrippingProtocol> {
        self {
            self.userCachedStatus
        }
    }

    var contextProviderFactory: Factory<CoreDataContextProviderProtocol> {
        self {
            CoreDataService.shared
        }
    }

    var featureFlagCacheFactory: Factory<FeatureFlagCache> {
        self {
            self.userCachedStatus
        }
    }

    var internetConnectionStatusProviderFactory: Factory<InternetConnectionStatusProviderProtocol> {
        self {
            InternetConnectionStatusProvider.shared
        }
    }

    var keyMakerFactory: Factory<KeyMakerProtocol> {
        self {
            Keymaker(
                autolocker: Autolocker(lockTimeProvider: self.userCachedStatus),
                keychain: KeychainWrapper.keychain
            )
        }
    }

    var lastUpdatedStoreFactory: Factory<LastUpdatedStore> {
        self {
            LastUpdatedStore(contextProvider: self.contextProvider)
        }
    }

    var lockCacheStatusFactory: Factory<LockCacheStatus> {
        self {
            self.keyMaker
        }
    }

    var notificationCenterFactory: Factory<NotificationCenter> {
        self {
            .default
        }
    }

    var pinFailedCountCacheFactory: Factory<PinFailedCountCache> {
        self {
            self.userCachedStatus
        }
    }

    var queueManagerFactory: Factory<QueueManager> {
        self {
            let messageQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.name)
            let miscQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.miscName)
            return QueueManager(messageQueue: messageQueue, miscQueue: miscQueue)
        }
    }

    var unlockManagerFactory: Factory<UnlockManager> {
        self {
            UnlockManager(
                cacheStatus: self.lockCacheStatus,
                keyMaker: self.keyMaker,
                pinFailedCountCache: self.userCachedStatus,
                notificationCenter: self.notificationCenter
            )
        }
    }

    var usersManagerFactory: Factory<UsersManager> {
        self {
            UsersManager(
                doh: BackendConfiguration.shared.doh,
                userDataCache: UserDataCache(keyMaker: self.keyMaker),
                coreKeyMaker: self.keyMaker
            )
        }
    }

    var userCachedStatusFactory: Factory<UserCachedStatus> {
        self {
            UserCachedStatus()
        }
    }

    var userIntroductionProgressProviderFactory: Factory<UserIntroductionProgressProvider> {
        self {
            self.userCachedStatus
        }
    }

    init() {
        manager.defaultScope = .cached
    }
}
