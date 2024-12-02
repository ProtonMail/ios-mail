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
    typealias Dependencies = SingleMessageComponentsFactory.Dependencies
    & AttachmentViewModel.Dependencies
    & HasInternetConnectionStatusProviderProtocol

    private let components: SingleMessageComponentsFactory
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        components = SingleMessageComponentsFactory(dependencies: dependencies)
        self.dependencies = dependencies
    }

    func createViewModel(
        context: SingleMessageContentViewContext,
        highlightedKeywords: [String],
        goToDraft: @escaping (MessageID, Date?) -> Void
    ) -> SingleMessageContentViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                spamType: context.message.spam,
                user: dependencies.user,
                imageProxy: dependencies.imageProxy
            ),
            bannerViewModel: components.banner(labelId: context.labelId, message: context.message),
            attachments: .init(dependencies: dependencies)
        )
        return .init(context: context,
                     childViewModels: childViewModels,
                     user: dependencies.user,
                     internetStatusProvider: dependencies.internetConnectionStatusProvider,
                     dependencies: components.contentViewModelDependencies(
                        context: context,
                        highlightedKeywords: highlightedKeywords
                     ),
                     goToDraft: goToDraft)
    }

}

class SingleMessageViewModelFactory {
    typealias Dependencies = SingleMessageContentViewModelFactory.Dependencies & HasUserDefaults

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func createViewModel(labelId: LabelID,
                         message: MessageEntity,
                         highlightedKeywords: [String],
                         coordinator: SingleMessageCoordinator,
                         goToDraft: @escaping (MessageID, Date?) -> Void) -> SingleMessageViewModel {
        let contentContext = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            viewMode: .singleMessage
        )
        let user = dependencies.user
        return .init(
            labelId: labelId,
            message: message,
            user: user,
            userIntroductionProgressProvider: userCachedStatus,
            saveToolbarActionUseCase: SaveToolbarActionSettings(
                dependencies: .init(user: user)
            ),
            toolbarActionProvider: user,
            coordinator: coordinator,
            nextMessageAfterMoveStatusProvider: user,
            contentViewModel: SingleMessageContentViewModelFactory(dependencies: dependencies).createViewModel(
                context: contentContext,
                highlightedKeywords: highlightedKeywords,
                goToDraft: goToDraft
            ),
            contextProvider: dependencies.contextProvider,
            highlightedKeywords: highlightedKeywords,
            dependencies: dependencies
        )
    }

}

class SingleMessageComponentsFactory {
    typealias Dependencies = MessageInfoProvider.Dependencies
    & HasCoreDataContextProviderProtocol
    & HasFeatureFlagCache
    & HasFetchMessageDetailUseCase
    & HasKeychain
    & HasQueueManager
    & HasUnblockSender
    & HasUserCachedStatus

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func contentViewModelDependencies(
        context: SingleMessageContentViewContext,
        highlightedKeywords: [String]
    ) -> SingleMessageContentViewModel.Dependencies {
        let contextProvider = dependencies.contextProvider
        let incomingDefaultService = dependencies.user.incomingDefaultService
        let queueManager = dependencies.queueManager
        let user = dependencies.user

        let blockSender = BlockSender(
            dependencies: .init(
                incomingDefaultService: incomingDefaultService,
                queueManager: queueManager,
                userInfo: user.userInfo
            )
        )

        let isSenderBlockedPublisher = IsSenderBlockedPublisher(contextProvider: contextProvider, userID: user.userID)

        let messageInfoProvider = MessageInfoProvider(
            message: context.message,
            systemUpTime: dependencies.userCachedStatus,
            labelID: context.labelId,
            dependencies: dependencies,
            highlightedKeywords: highlightedKeywords
        )

        return .init(
            blockSender: blockSender,
            fetchMessageDetail: dependencies.fetchMessageDetail,
            isSenderBlockedPublisher: isSenderBlockedPublisher, 
            keychain: dependencies.keychain,
            messageInfoProvider: messageInfoProvider,
            unblockSender: dependencies.unblockSender,
            checkProtonServerStatus: CheckProtonServerStatus(),
            featureFlagCache: dependencies.featureFlagCache
        )
    }

    func messageBody(
        spamType: SpamType?,
        user: UserManager,
        imageProxy: ImageProxy
    ) -> NewMessageBodyViewModel {
        return .init(
            spamType: spamType,
            internetStatusProvider: InternetConnectionStatusProvider.shared,
            linkConfirmation: user.userInfo.linkConfirmation,
            userKeys: user.toUserKeys(),
            imageProxy: imageProxy
        )
    }

    func banner(labelId: LabelID, message: MessageEntity) -> BannerViewModel {
        let user = dependencies.user
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
        return .init(
            shouldAutoLoadRemoteContent: user.userInfo.isAutoLoadRemoteContentEnabled,
            expirationTime: message.expirationTime,
            shouldAutoLoadEmbeddedImage: user.userInfo.isAutoLoadEmbeddedImagesEnabled,
            unsubscribeActionHandler: unsubscribeService,
            markLegitimateActionHandler: markLegitimateService,
            receiptActionHandler: receiptService,
            urlOpener: UIApplication.shared,
            viewMode: user.userInfo.viewMode
        )
    }
}
