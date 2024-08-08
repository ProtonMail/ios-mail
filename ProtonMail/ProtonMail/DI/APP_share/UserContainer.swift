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
import ProtonCoreServices

final class UserContainer: ManagedContainer {
    let manager = ContainerManager()
    unowned let userManager: UserManager
    let globalContainer: GlobalContainer

    var apiServiceFactory: Factory<APIService> {
        self {
            self.user.apiService
        }
    }

    var autoImportContactsFeatureFactory: Factory<AutoImportContactsFeature> {
        self {
            AutoImportContactsFeature(dependencies: self)
        }
    }

    var cacheServiceFactory: Factory<CacheService> {
        self {
            CacheService(userID: self.user.userID, dependencies: self)
        }
    }

    var contactSyncQueueFactory: Factory<ContactsSyncQueueProtocol> {
        self {
            ContactsSyncQueue(userID: self.user.userID, dependencies: self)
        }
    }

    var composerViewFactoryFactory: Factory<ComposerViewFactory> {
        self {
            ComposerViewFactory(dependencies: self)
        }
    }

    var contactServiceFactory: Factory<ContactDataService> {
        self {
            ContactDataService(
                api: self.apiService,
                labelDataService: self.labelService,
                userInfo: self.user.userInfo,
                coreDataService: self.contextProvider,
                cacheService: self.cacheService,
                queueManager: self.queueManager,
                userDefaults: self.userDefaults
            )
        }
    }

    var contactGroupServiceFactory: Factory<ContactGroupsDataService> {
        self {
            ContactGroupsDataService(
                api: self.apiService,
                labelDataService: self.labelService,
                coreDataService: self.contextProvider,
                queueManager: self.queueManager,
                userID: self.user.userID
            )
        }
    }

    var conversationServiceFactory: Factory<ConversationDataServiceProxy> {
        self {
            ConversationDataServiceProxy(
                api: self.apiService,
                userID: self.user.userID,
                contextProvider: self.contextProvider,
                lastUpdatedStore: self.lastUpdatedStore,
                messageDataService: self.messageService,
                eventsService: self.eventsService,
                undoActionManager: self.undoActionManager,
                queueManager: self.queueManager,
                userDefaults: self.userDefaults,
                localConversationUpdater: .init(userID: self.user.userID.rawValue, dependencies: self)
            )
        }
    }

    var conversationStateServiceFactory: Factory<ConversationStateService> {
        self {
            ConversationStateService(viewMode: self.user.userInfo.viewMode)
        }
    }

    var eventProcessorFactory: Factory<EventProcessor> {
        self {
            EventProcessor(dependencies: self)
        }
    }

    var eventsServiceFactory: Factory<EventsFetching> {
        self {
            EventsService(userManager: self.user, dependencies: self)
        }
    }

    var featureFlagsDownloadServiceFactory: Factory<FeatureFlagsDownloadService> {
        self {
            FeatureFlagsDownloadService(
                cache: self.userCachedStatus,
                userID: self.user.userID,
                apiService: self.apiService,
                appRatingStatusProvider: self.appRatingStatusProvider
            )
        }
    }

    var featureFlagProviderFactory: Factory<FeatureFlagProvider> {
        self {
            FeatureFlagProviderImpl(featureFlagsRepository: self.featureFlagsRepository, userID: self.user.userID)
        }
    }

    var fetchAndVerifyContactsFactory: Factory<FetchAndVerifyContactsUseCase> {
        self {
            FetchAndVerifyContacts(user: self.user)
        }
    }

    var fetchAttachmentFactory: Factory<FetchAttachmentUseCase> {
        self {
            FetchAttachment(dependencies: .init(apiService: self.user.apiService))
        }
    }

    var fetchAttachmentMetadataFactory: Factory<FetchAttachmentMetadataUseCase> {
        self {
            FetchAttachmentMetadata(dependencies: .init(apiService: self.user.apiService))
        }
    }

    var fetchEmailAddressesPublicKeyFactory: Factory<FetchEmailAddressesPublicKey> {
        self {
            FetchEmailAddressesPublicKey(dependencies: .init(apiService: self.user.apiService))
        }
    }

    var fetchMessageDetailFactory: Factory<FetchMessageDetailUseCase> {
        self {
            FetchMessageDetail(
                dependencies: .init(
                    queueManager: self.queueManager,
                    apiService: self.apiService,
                    contextProvider: self.contextProvider
                )
            )
        }
    }

    var fetchMessageMetaDataFactory: Factory<FetchMessageMetaData> {
        self {
            FetchMessageMetaData(
                dependencies: .init(
                    userID: self.user.userID,
                    messageDataService: self.messageService,
                    contextProvider: self.contextProvider,
                    queueManager: self.queueManager
                )
            )
        }
    }

    var imageProxyFactory: Factory<ImageProxy> {
        self {
            #if APP_EXTENSION
            ImageProxy(dependencies: .init(apiService: self.user.apiService, imageCache: nil))
            #else
            ImageProxy(dependencies: .init(apiService: self.user.apiService, imageCache: self.imageProxyCache))
            #endif
        }
    }

    var incomingDefaultServiceFactory: Factory<IncomingDefaultService> {
        self {
            IncomingDefaultService(
                dependencies: .init(
                    apiService: self.apiService,
                    contextProvider: self.contextProvider,
                    userInfo: self.user.userInfo
                )
            )
        }
    }

    var labelServiceFactory: Factory<LabelsDataService> {
        self {
            LabelsDataService(userID: self.user.userID, dependencies: self)
        }
    }

    var localNotificationServiceFactory: Factory<LocalNotificationService> {
        self {
            LocalNotificationService(userID: self.user.userID)
        }
    }

    var messageServiceFactory: Factory<MessageDataService> {
        self {
            MessageDataService(
                api: self.apiService,
                userID: self.user.userID,
                labelDataService: self.labelService,
                localNotificationService: self.localNotificationService,
                queueManager: self.queueManager,
                contextProvider: self.contextProvider,
                lastUpdatedStore: self.lastUpdatedStore,
                user: self.user,
                cacheService: self.cacheService,
                dependencies: .init(
                    moveMessageInCacheUseCase: MoveMessageInCache(
                        dependencies: .init(
                            contextProvider: self.contextProvider,
                            lastUpdatedStore: self.lastUpdatedStore,
                            userID: self.user.userID,
                            pushUpdater: self.pushUpdater
                        )
                    ),
                    pushUpdater: self.pushUpdater
                )
            )
        }
    }

    var queueHandlerFactory: Factory<QueueHandler> {
        self {
            MainQueueHandler(
                coreDataService: self.contextProvider,
                fetchMessageDetail: self.fetchMessageDetail,
                apiService: self.apiService,
                messageDataService: self.messageService,
                conversationDataService: self.conversationService.conversationDataService,
                labelDataService: self.labelService,
                localNotificationService: self.localNotificationService,
                undoActionManager: self.undoActionManager,
                user: self.user
            )
        }
    }

    var telemetryServiceFactory: Factory<TelemetryServiceProtocol> {
        self {
            TelemetryService(
                userID: self.user.userID,
                shouldBuildSendTelemetry: !Application.isTestingBuild,
                isTelemetrySettingOn: { [weak self] in self?.user.hasTelemetryEnabled ?? false },
                dependencies: self
            )
        }
    }

    var undoActionManagerFactory: Factory<UndoActionManagerProtocol> {
        self {
            UndoActionManager(dependencies: self)
        }
    }

    var userServiceFactory: Factory<UserDataService> {
        self {
            UserDataService(apiService: self.apiService)
        }
    }

    var userFactory: Factory<UserManager> {
        self {
            self.userManager
        }
        .scope(.shared)
    }

    init(userManager: UserManager, globalContainer: GlobalContainer) {
        self.userManager = userManager
        self.globalContainer = globalContainer

        manager.defaultScope = .cached
    }
}
