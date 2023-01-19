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
        internetStatusProvider: InternetConnectionStatusProvider,
        systemUpTime: SystemUpTimeProtocol,
        dependencies: SingleMessageContentViewModel.Dependencies,
        goToDraft: @escaping (MessageID, OriginalScheduleDate?) -> Void
    ) -> SingleMessageContentViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                spamType: context.message.spam,
                user: user
            ),
            nonExpandedHeader: .init(isScheduledSend: context.message.isScheduledSend),
            bannerViewModel: components.banner(labelId: context.labelId, message: context.message, user: user),
            attachments: .init()
        )
        return .init(context: context,
                     childViewModels: childViewModels,
                     user: user,
                     internetStatusProvider: internetStatusProvider,
                     systemUpTime: systemUpTime,
                     dependencies: dependencies,
                     goToDraft: goToDraft)
    }

}

class SingleMessageViewModelFactory {
    private let components = SingleMessageComponentsFactory()

    func createViewModel(labelId: LabelID,
                         message: MessageEntity,
                         user: UserManager,
                         systemUpTime: SystemUpTimeProtocol,
                         internetStatusProvider: InternetConnectionStatusProvider,
                         goToDraft: @escaping (MessageID, OriginalScheduleDate?) -> Void) -> SingleMessageViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                spamType: message.spam,
                user: user
            ),
            nonExpandedHeader: .init(isScheduledSend: message.isScheduledSend),
            bannerViewModel: components.banner(labelId: labelId, message: message, user: user),
            attachments: .init()
        )
        let fetchMessageDetail = FetchMessageDetail(
            dependencies: .init(
                queueManager: sharedServices.get(by: QueueManager.self),
                apiService: user.apiService,
                contextProvider: sharedServices.get(by: CoreDataService.self),
                realAttachmentsFlagProvider: userCachedStatus,
                messageDataAction: user.messageService,
                cacheService: user.cacheService
            )
        )
        let dependencies: SingleMessageContentViewModel.Dependencies = .init(fetchMessageDetail: fetchMessageDetail)
        return .init(
            labelId: labelId,
            message: message,
            user: user,
            childViewModels: childViewModels,
            internetStatusProvider: internetStatusProvider,
            userIntroductionProgressProvider: userCachedStatus,
            saveToolbarActionUseCase: SaveToolbarActionSettings(
                dependencies: .init(user: user)
            ),
            toolbarActionProvider: user,
            toolbarCustomizeSpotlightStatusProvider: userCachedStatus,
            systemUpTime: systemUpTime,
            dependencies: dependencies,
            goToDraft: goToDraft
        )
    }

}

class SingleMessageComponentsFactory {

    func messageBody(spamType: SpamType?, user: UserManager) -> NewMessageBodyViewModel {
        return .init(
            spamType: spamType,
            internetStatusProvider: InternetConnectionStatusProvider(),
            linkConfirmation: user.userInfo.linkConfirmation,
            userKeys: user.toUserKeys()
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
