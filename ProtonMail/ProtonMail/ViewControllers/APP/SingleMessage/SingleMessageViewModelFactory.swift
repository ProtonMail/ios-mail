//
//  SingleMessageViewModelFactory.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

class SingleMessageContentViewModelFactory {
    private let components = SingleMessageComponentsFactory()

    func createViewModel(
        context: SingleMessageContentViewContext,
        user: UserManager,
        highlightedKeywords: [String],
        goToDraft: @escaping (MessageID, Date?) -> Void
    ) -> SingleMessageContentViewModel {
        let imageProxy = ImageProxy(dependencies: .init(apiService: user.apiService))
        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                spamType: context.message.spam,
                user: user,
                imageProxy: imageProxy
            ),
            bannerViewModel: components.banner(labelId: context.labelId, message: context.message, user: user),
            attachments: .init()
        )
        return .init(context: context,
                     childViewModels: childViewModels,
                     user: user,
                     dependencies: components.contentViewModelDependencies(
                        context: context,
                        highlightedKeywords: highlightedKeywords,
                        imageProxy: imageProxy,
                        user: user
                     ),
                     highlightedKeywords: highlightedKeywords,
                     goToDraft: goToDraft)
    }

}

class SingleMessageViewModelFactory {
    private let components = SingleMessageComponentsFactory()

    func createViewModel(labelId: LabelID,
                         message: MessageEntity,
                         user: UserManager,
                         highlightedKeywords: [String],
                         coordinator: SingleMessageCoordinator,
                         goToDraft: @escaping (MessageID, Date?) -> Void) -> SingleMessageViewModel {
        let contentContext = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            viewMode: .singleMessage
        )
        return .init(
            labelId: labelId,
            message: message,
            user: user,
            userIntroductionProgressProvider: userCachedStatus,
            saveToolbarActionUseCase: SaveToolbarActionSettings(
                dependencies: .init(user: user)
            ),
            toolbarActionProvider: user,
            toolbarCustomizeSpotlightStatusProvider: userCachedStatus,
            coordinator: coordinator,
            nextMessageAfterMoveStatusProvider: user,
            contentViewModel: SingleMessageContentViewModelFactory().createViewModel(
                context: contentContext,
                user: user,
                highlightedKeywords: highlightedKeywords,
                goToDraft: goToDraft
            ),
            highlightedKeywords: highlightedKeywords
        )
    }

}

class SingleMessageComponentsFactory {
    func contentViewModelDependencies(
        context: SingleMessageContentViewContext,
        highlightedKeywords: [String],
        imageProxy: ImageProxy,
        user: UserManager
    ) -> SingleMessageContentViewModel.Dependencies {
        let contextProvider = sharedServices.get(by: CoreDataService.self)
        let incomingDefaultService = user.incomingDefaultService
        let internetStatusProvider = InternetConnectionStatusProvider()
        let queueManager = sharedServices.get(by: QueueManager.self)

        let blockSender = BlockSender(
            dependencies: .init(
                incomingDefaultService: incomingDefaultService,
                queueManager: queueManager,
                userInfo: user.userInfo
            )
        )

        let fetchMessageDetail = FetchMessageDetail(
            dependencies: .init(
                queueManager: queueManager,
                apiService: user.apiService,
                contextProvider: contextProvider,
                cacheService: user.cacheService
            )
        )

        let unblockSender = UnblockSender(
            dependencies: .init(
                incomingDefaultService: incomingDefaultService,
                queueManager: queueManager,
                userInfo: user.userInfo
            )
        )

        let isSenderBlockedPublisher = IsSenderBlockedPublisher(contextProvider: contextProvider, userID: user.userID)

        let messageInfoProviderDependencies = MessageInfoProvider.Dependencies(
            imageProxy: imageProxy,
            fetchAttachment: FetchAttachment(dependencies: .init(apiService: user.apiService)),
            fetchSenderImage: FetchSenderImage(
                dependencies: .init(
                    featureFlagCache: sharedServices.userCachedStatus,
                    senderImageService: .init(
                        dependencies: .init(
                            apiService: user.apiService,
                            internetStatusProvider: internetStatusProvider
                        )
                    ),
                    mailSettings: user.mailSettings
                )
            ), darkModeCache: sharedServices.userCachedStatus
        )

        let messageInfoProvider = MessageInfoProvider(
            message: context.message,
            user: user,
            systemUpTime: sharedServices.userCachedStatus,
            labelID: context.labelId,
            dependencies: messageInfoProviderDependencies,
            highlightedKeywords: highlightedKeywords
        )

        return .init(
            blockSender: blockSender,
            fetchMessageDetail: fetchMessageDetail,
            isSenderBlockedPublisher: isSenderBlockedPublisher,
            messageInfoProvider: messageInfoProvider,
            unblockSender: unblockSender
        )
    }

    func messageBody(
        spamType: SpamType?,
        user: UserManager,
        imageProxy: ImageProxy
    ) -> NewMessageBodyViewModel {
        return .init(
            spamType: spamType,
            internetStatusProvider: InternetConnectionStatusProvider(),
            linkConfirmation: user.userInfo.linkConfirmation,
            userKeys: user.toUserKeys(),
            imageProxy: imageProxy
        )
    }

    func banner(labelId: LabelID, message: MessageEntity, user: UserManager) -> BannerViewModel {
        let unsubscribeService = UnsubscribeService(
            labelId: labelId,
            apiService: user.apiService,
            eventsService: user.eventsService
        )
        let markLegitimateService = MarkLegitimateService(
            labelId: labelId,
            apiService: user.apiService,
            eventsService: user.eventsService
        )
        let receiptService = ReceiptService(labelID: labelId,
                                            apiService: user.apiService,
                                            eventsService: user.eventsService)
        return .init(shouldAutoLoadRemoteContent: user.userInfo.isAutoLoadRemoteContentEnabled,
                     expirationTime: message.expirationTime,
                     shouldAutoLoadEmbeddedImage: user.userInfo.isAutoLoadEmbeddedImagesEnabled,
                     unsubscribeActionHandler: unsubscribeService,
                     markLegitimateActionHandler: markLegitimateService,
                     receiptActionHandler: receiptService,
                     urlOpener: UIApplication.shared)
    }
}
