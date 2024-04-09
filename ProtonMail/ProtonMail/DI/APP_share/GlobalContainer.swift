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
import ProtonCoreEventsLoop
import ProtonCoreFeatureFlags
import ProtonCoreKeymaker

class GlobalContainer: ManagedContainer {
    let manager = ContainerManager()

    var appAccessResolverFactory: Factory<AppAccessResolver> {
        self {
            AppAccessResolver(dependencies: self)
        }
    }

    var appRatingStatusProviderFactory: Factory<AppRatingStatusProvider> {
        self {
            UserDefaultsAppRatingStatusProvider(userDefaults: self.userDefaults)
        }
    }

    var cachedUserDataProviderFactory: Factory<CachedUserDataProvider> {
        self {
            UserDataCache(keyMaker: self.keyMaker, keychain: self.keychain)
        }
    }

    var contextProviderFactory: Factory<CoreDataContextProviderProtocol> {
        self {
            CoreDataService(container: CoreDataStore.shared.container)
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

    var keychainFactory: Factory<Keychain> {
        self {
            KeychainWrapper.keychain
        }
    }

    var keyMakerFactory: Factory<KeyMakerProtocol> {
        self {
            Keymaker(
                autolocker: Autolocker(lockTimeProvider: self.keychain),
                keychain: self.keychain
            )
        }
    }

    var lastUpdatedStoreFactory: Factory<LastUpdatedStoreProtocol> {
        self {
            LastUpdatedStore(contextProvider: self.contextProvider)
        }
    }

    var lockCacheStatusFactory: Factory<LockCacheStatus> {
        self {
            self.keyMaker
        }
    }

    var lockPreventorFactory: Factory<LockPreventor> {
        self {
            LockPreventor.shared
        }
    }

    var launchServiceFactory: Factory<LaunchService> {
        self {
            Launch(dependencies: self)
        }
	}

    var mailEventsPeriodicSchedulerFactory: Factory<MailEventsPeriodicScheduler> {
        self {
            MailEventsPeriodicScheduler(
                refillPeriod: Constants.App.eventsPollingInterval,
                coreLoopFactory: AnyCoreLoopFactory(EmptyCoreLoopFactory()),
                specialLoopFactory: AnySpecialLoopFactory(MailEventsSpecialLoopFactory(dependencies: self))
            )
        }
    }

    var notificationCenterFactory: Factory<NotificationCenter> {
        self {
            .default
        }
    }

    var pinCodeProtectionFactory: Factory<PinCodeProtection> {
        self {
            DefaultPinCodeProtection(dependencies: self)
        }
    }

    var pinCodeVerifierFactory: Factory<PinCodeVerifier> {
        self {
            DefaultPinCodeVerifier(dependencies: self)
        }
    }

    var pushUpdaterFactory: Factory<PushUpdater> {
        self {
            PushUpdater(userDefaults: self.userDefaults)
        }
    }

    var queueManagerFactory: Factory<QueueManager> {
        self {
            let messageQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.name)
            let miscQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.miscName)
            return QueueManager(messageQueue: messageQueue, miscQueue: miscQueue)
        }
    }

    var resumeAfterUnlockFactory: Factory<ResumeAfterUnlock> {
        self {
            #if !APP_EXTENSION
            AppResumeAfterUnlock(dependencies: self)
            #else
            EmptyResumeAfterUnlock()
            #endif
        }
    }

    var setupCoreDataServiceFactory: Factory<SetupCoreDataService> {
        self {
            SetupCoreData()
        }
    }

    var unlockManagerFactory: Factory<UnlockManager> {
        self {
            UnlockManager(
                cacheStatus: self.lockCacheStatus,
                keychain: self.keychain,
                keyMaker: self.keyMaker,
                userDefaults: self.userDefaults,
                notificationCenter: self.notificationCenter
            )
        }
    }

    var unlockServiceFactory: Factory<UnlockService> {
        self {
            Unlock(dependencies: self)
        }
    }

    var userDefaultsFactory: Factory<UserDefaults> {
        self {
            UserDefaults(suiteName: Constants.AppGroup)!
        }
    }

    var usersManagerFactory: Factory<UsersManager> {
        self {
            UsersManager(dependencies: self)
        }
    }

    var userCachedStatusFactory: Factory<UserCachedStatus> {
        self {
            UserCachedStatus(userDefaults: self.userDefaults, keychain: self.keychain)
        }
    }

    var userIntroductionProgressProviderFactory: Factory<UserIntroductionProgressProvider> {
        self {
            self.userCachedStatus
        }
    }

    @available(*, deprecated, message: "Prefer `FeatureFlagProvider`")
    var featureFlagsRepositoryFactory: Factory<FeatureFlagsRepository> {
        self {
            FeatureFlagsRepository.shared
        }
    }

    init() {
        manager.defaultScope = .cached

#if !APP_EXTENSION
        trackLifetime()
#endif
    }
}
