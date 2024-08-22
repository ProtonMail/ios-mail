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
import ProtonCorePayments
import ProtonInboxRSVP

extension UserContainer {
    var answerInvitationFactory: Factory<AnswerInvitation> {
        self {
            AnswerInvitationWrapper(dependencies: self)
        }
    }

    var appRatingServiceFactory: Factory<AppRatingService> {
        self {
            AppRatingService(
                dependencies: .init(
                    featureFlagService: self.featureFlagsDownloadService,
                    appRating: AppRatingManager(),
                    internetStatus: self.internetConnectionStatusProvider,
                    appRatingStatusProvider: self.appRatingStatusProvider
                )
            )
        }
    }

    var blockedSenderCacheUpdaterFactory: Factory<BlockedSenderCacheUpdater> {
        self {
            let refetchAllBlockedSenders = RefetchAllBlockedSenders(
                dependencies: .init(incomingDefaultService: self.incomingDefaultService)
            )

            return BlockedSenderCacheUpdater(
                dependencies: .init(
                    fetchStatusProvider: self.userCachedStatus,
                    internetConnectionStatusProvider: self.internetConnectionStatusProvider,
                    refetchAllBlockedSenders: refetchAllBlockedSenders,
                    userInfo: self.user.userInfo
                )
            )
        }
    }

    var cleanUserLocalMessagesFactory: Factory<CleanUserLocalMessages> {
        self {
            CleanUserLocalMessages(dependencies: self)
        }
    }

    var emailAddressStorageFactory: Factory<EmailAddressStorage> {
        self {
            UserBasedEmailAddressStorage(dependencies: self)
        }
    }

    var reportServiceFactory: Factory<BugReportService> {
        self {
            BugReportService(api: self.apiService)
        }
    }

    var contactViewsFactoryFactory: Factory<ContactViewsFactory> {
        self {
            ContactViewsFactory(dependencies: self)
        }
    }

    var extractBasicEventInfoFactory: Factory<ExtractBasicEventInfo> {
        self {
            ExtractBasicEventInfoImpl()
        }
    }

    var fetchEventDetailsFactory: Factory<FetchEventDetails> {
        self {
            FetchEventDetailsImpl(dependencies: self)
        }
    }

    var fetchMessagesFactory: Factory<FetchMessages> {
        self {
            FetchMessages(
                dependencies: .init(
                    messageDataService: self.messageService,
                    cacheService: self.cacheService,
                    eventsService: self.eventsService
                )
            )
        }
    }

    var fetchSenderImageFactory: Factory<FetchSenderImage> {
        self {
            FetchSenderImage(
                dependencies: .init(
                    featureFlagCache: self.featureFlagCache,
                    senderImageService: .init(
                        dependencies: .init(
                            apiService: self.user.apiService,
                            internetStatusProvider: self.internetConnectionStatusProvider,
                            imageCache: self.senderImageCache
                        )
                    ),
                    mailSettings: self.user.mailSettings
                )
            )
        }
    }

    var importDeviceContactsFactory: Factory<ImportDeviceContacts> {
        self {
            ImportDeviceContacts(userID: self.user.userID, dependencies: self)
        }
    }

    var messageSearchFactory: Factory<SearchUseCase> {
        self {
            MessageSearch(
                dependencies: .init(
                    backendSearch: BackendSearch(
                        dependencies: .init(
                            apiService: self.user.apiService,
                            contextProvider: self.contextProvider,
                            userID: self.user.userID
                        )
                    )
                )
            )
        }
    }

    var nextMessageAfterMoveStatusProviderFactory: Factory<NextMessageAfterMoveStatusProvider> {
        self {
            self.user
        }
        .scope(.shared)
    }

    var onboardingUpsellPageFactoryFactory: Factory<OnboardingUpsellPageFactory> {
        self {
            OnboardingUpsellPageFactory(dependencies: self)
        }
    }

    var paymentsFactory: Factory<Payments> {
        self {
            Payments(
                inAppPurchaseIdentifiers: Constants.mailPlanIDs,
                apiService: self.apiService,
                localStorage: ServicePlanDataStorageImpl(userDefaults: self.userDefaults),
                canExtendSubscription: true,
                reportBugAlertHandler: { _ in
                    let link = DeepLink("toBugPop", sender: nil)
                    NotificationCenter.default.post(name: .switchView, object: link)
                }
            )
        }
    }

    var paymentsUIFactoryFactory: Factory<PaymentsUIFactory> {
        self {
            PaymentsUIFactory(dependencies: self)
        }
    }

    var planServiceFactory: Factory<PlanService> {
        self {
            self.payments.planService
        }
    }

    var purchaseManagerFactory: Factory<PurchaseManagerProtocol> {
        self {
            self.payments.purchaseManager
        }
    }

    var purchasePlanFactory: Factory<PurchasePlan> {
        self {
            PurchasePlan(dependencies: self)
        }
    }

    var settingsViewsFactoryFactory: Factory<SettingsViewsFactory> {
        self {
            SettingsViewsFactory(dependencies: self)
        }
    }

    var saveToolbarActionSettingsFactory: Factory<SaveToolbarActionSettings> {
        self {
            SaveToolbarActionSettings(dependencies: .init(user: self.user))
        }
    }

    var sendBugReportFactory: Factory<SendBugReport> {
        self {
            SendBugReport(
                bugReportService: self.user.reportService,
                internetConnectionStatusProvider: self.internetConnectionStatusProvider
            )
        }
    }

    var storeKitManagerFactory: Factory<StoreKitManagerProtocol> {
        self {
            self.payments.storeKitManager
        }
    }

    var toolbarActionProviderFactory: Factory<ToolbarActionProvider> {
        self {
            self.user
        }
        .scope(.shared)
    }

    var toolbarSettingViewFactoryFactory: Factory<ToolbarSettingViewFactory> {
        self {
            ToolbarSettingViewFactory(dependencies: self)
        }
    }

    var unblockSenderFactory: Factory<UnblockSender> {
        self {
            UnblockSender(
                dependencies: .init(
                    incomingDefaultService: self.user.incomingDefaultService,
                    queueManager: self.queueManager,
                    userInfo: self.user.userInfo
                )
            )
        }
    }

    var updateMailboxFactory: Factory<UpdateMailbox> {
        self {
            let purgeOldMessages = PurgeOldMessages(user: self.user, coreDataService: self.contextProvider)

            let fetchLatestEventID = FetchLatestEventId(
                userId: self.user.userID,
                dependencies: .init(apiService: self.apiService, lastUpdatedStore: self.lastUpdatedStore)
            )

            let fetchMessagesWithReset = FetchMessagesWithReset(
                userID: self.user.userID,
                dependencies: FetchMessagesWithReset.Dependencies(
                    fetchLatestEventId: fetchLatestEventID,
                    fetchMessages: self.fetchMessages,
                    localMessageDataService: self.messageService,
                    lastUpdatedStore: self.lastUpdatedStore,
                    contactProvider: self.contactService,
                    labelProvider: self.labelService
                )
            )

            return UpdateMailbox(
                dependencies: .init(
                    eventService: self.eventsService,
                    messageDataService: self.messageService,
                    conversationProvider: self.conversationService,
                    purgeOldMessages: purgeOldMessages,
                    fetchMessageWithReset: fetchMessagesWithReset,
                    fetchMessage: self.fetchMessages,
                    fetchLatestEventID: fetchLatestEventID,
                    internetConnectionStatusProvider: self.internetConnectionStatusProvider,
                    userDefaults: self.userDefaults
                )
            )
        }
    }

    var upsellButtonStateProviderFactory: Factory<UpsellButtonStateProvider> {
        self {
            .init(dependencies: self)
        }
    }

    var upsellPageFactoryFactory: Factory<UpsellPageFactory> {
        self {
            UpsellPageFactory(dependencies: self)
        }
    }

    var upsellOfferProviderFactory: Factory<UpsellOfferProvider> {
        self {
            UpsellOfferProviderImpl(dependencies: self)
        }
    }

    var upsellTelemetryReporterFactory: Factory<UpsellTelemetryReporter> {
        self {
            UpsellTelemetryReporter(dependencies: self)
        }
    }
}
