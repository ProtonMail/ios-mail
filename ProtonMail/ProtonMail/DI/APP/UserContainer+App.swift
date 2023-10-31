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

extension UserContainer {
    var appRatingServiceFactory: Factory<AppRatingService> {
        self {
            AppRatingService(
                dependencies: .init(
                    featureFlagService: self.featureFlagsDownloadService,
                    appRating: AppRatingManager(),
                    internetStatus: self.internetConnectionStatusProvider,
                    appRatingPrompt: self.userCachedStatus
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
            CleanUserLocalMessages(
                contactCacheStatus: self.userCachedStatus,
                fetchInboxMessages: FetchMessages(
                    dependencies: .init(
                        messageDataService: self.messageService,
                        cacheService: self.cacheService,
                        eventsService: self.eventsService
                    )
                ),
                dependencies: self
            )
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

    var messageSearchFactory: Factory<SearchUseCase> {
        self {
            MessageSearch(
                dependencies: .init(
                    userID: self.user.userID,
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

    var paymentsFactory: Factory<Payments> {
        self {
            Payments(
                inAppPurchaseIdentifiers: Constants.mailPlanIDs,
                apiService: self.apiService,
                localStorage: self.userCachedStatus,
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
}
