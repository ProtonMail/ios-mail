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
import LifetimeTracker
import UIKit

extension GlobalContainer {
    var addressBookServiceFactory: Factory<AddressBookService> {
        self {
            AddressBookService()
        }
    }

    var backgroundTaskHelperFactory: Factory<BackgroundTaskHelper> {
        self {
            BackgroundTaskHelper(
                dependencies: .init(
                    coreKeyMaker: self.keyMaker,
                    usersManager: self.usersManager
                )
            )
        }
    }

    var biometricStatusProviderFactory: Factory<BiometricStatusProvider> {
        self {
            UIDevice.current
        }
    }

    var checkProtonServerStatusFactory: Factory<CheckProtonServerStatus> {
        self {
            CheckProtonServerStatus()
        }
    }

    var cleanCacheFactory: Factory<CleanCache> {
        self {
            CleanCache(dependencies: .init(usersManager: self.usersManager, imageProxyCache: self.imageProxyCache))
        }
    }

    var contactPickerModelHelperFactory: Factory<ContactPickerModelHelper> {
        self {
            ContactPickerModelHelper(contextProvider: self.contextProvider)
        }
    }

    var deviceContactsFactory: Factory<DeviceContactsProvider> {
        self {
            DeviceContacts()
        }
    }

    var imageProxyCacheFactory: Factory<ImageProxyCacheProtocol> {
        self {
            ImageProxyCache(dependencies: self)
        }
    }

    var mailboxMessageCellHelperFactory: Factory<MailboxMessageCellHelper> {
        self {
            MailboxMessageCellHelper(contactPickerModelHelper: self.contactPickerModelHelper)
        }
    }

    var pushServiceFactory: Factory<PushNotificationService> {
        self {
            let dependencies = PushNotificationService.Dependencies(
                actionsHandler: PushNotificationActionsHandler(
                    dependencies: .init(
                        queue: self.queueManager,
                        lockCacheStatus: self.lockCacheStatus,
                        usersManager: self.usersManager
                    )
                ),
                usersManager: self.usersManager,
                unlockProvider: self.unlockManager,
                pushEncryptionManager: PushEncryptionManager(
                    dependencies: .init(
                        usersManager: self.usersManager,
                        deviceRegistration: DeviceRegistration(dependencies: .init(usersManager: self.usersManager))
                    )
                )
            )
            return PushNotificationService(dependencies: dependencies)
        }
    }

    var saveSwipeActionSettingFactory: Factory<SaveSwipeActionSettingForUsersUseCase> {
        self {
            SaveSwipeActionSetting(dependencies: self)
        }
    }

    var senderImageCacheFactory: Factory<SenderImageCache> {
        self {
            SenderImageCache(dependencies: self)
        }
    }

    var signInManagerFactory: Factory<SignInManager> {
        self {
            let updateSwipeActionUseCase = UpdateSwipeActionDuringLogin(dependencies: self)
            return SignInManager(
                usersManager: self.usersManager,
                queueHandlerRegister: self.queueManager,
                updateSwipeActionUseCase: updateSwipeActionUseCase,
                dependencies: .init(notificationCenter: self.notificationCenter, userDefaults: self.userDefaults)
            )
        }
    }

    var storeKitManagerDelegateFactory: Factory<StoreKitManagerDelegateImpl> {
        self {
            StoreKitManagerDelegateImpl(dependencies: self)
        }
    }

    var swipeActionCacheFactory: Factory<SwipeActionCacheProtocol> {
        self {
            self.userCachedStatus
        }
    }

    var urlOpenerFactory: Factory<URLOpener> {
        self {
            UIApplication.shared
        }
    }

    var userNotificationCenterFactory: Factory<UserNotificationCenterProtocol> {
        self {
            UNUserNotificationCenter.current()
        }
    }
}

extension GlobalContainer: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
