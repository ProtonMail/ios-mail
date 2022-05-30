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

class SingleMessageContentViewModelFactory {

    func createViewModel(
        context: SingleMessageContentViewContext,
        user: UserManager,
        internetStatusProvider: InternetConnectionStatusProvider,
        isDarkModeEnableClosure: @escaping () -> Bool
    ) -> SingleMessageContentViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: messageBody(message: context.message, user: user, isDarkModeEnableClosure: isDarkModeEnableClosure),
            nonExpandedHeader: .init(labelId: context.labelId, message: context.message, user: user),
            bannerViewModel: banner(labelId: context.labelId, message: context.message, user: user),
            attachments: attachments(message: context.message)
        )
        return .init(context: context, childViewModels: childViewModels, user: user, internetStatusProvider: internetStatusProvider)
    }

    private func messageBody(message: MessageEntity,
                             user: UserManager,
                             isDarkModeEnableClosure: @escaping () -> Bool) -> NewMessageBodyViewModel {
        .init(
            message: message,
            messageDataProcessor: user.messageService,
            userAddressUpdater: user,
            shouldAutoLoadRemoteImages: user.userinfo.showImages.contains(.remote),
            shouldAutoLoadEmbeddedImages: user.userinfo.showImages.contains(.embedded),
            internetStatusProvider: InternetConnectionStatusProvider(),
            isDarkModeEnableClosure: isDarkModeEnableClosure,
            linkConfirmation: user.userinfo.linkConfirmation
        )
    }

    private func banner(labelId: LabelID, message: MessageEntity, user: UserManager) -> BannerViewModel {
        let unsubscribeService = UnsubscribeService(
            labelId: labelId,
            apiService: user.apiService,
            messageDataService: user.messageService,
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
            message: message,
            shouldAutoLoadRemoteContent: user.userinfo.showImages.contains(.remote),
            expirationTime: message.expirationTime,
            shouldAutoLoadEmbeddedImage: user.userinfo.showImages.contains(.embedded),
            unsubscribeService: unsubscribeService,
            markLegitimateService: markLegitimateService,
            receiptService: receiptService
        )
    }

    private func attachments(message: MessageEntity) -> AttachmentViewModel {
        let attachments: [AttachmentInfo] = message.attachments.map(AttachmentNormal.init)
        return .init(attachments: attachments)
    }

}

class SingleMessageViewModelFactory {

    func createViewModel(labelId: LabelID,
                         message: MessageEntity,
                         user: UserManager,
                         isDarkModeEnableClosure: @escaping () -> Bool) -> SingleMessageViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: messageBody(message: message, user: user, isDarkModeEnableClosure: isDarkModeEnableClosure),
            nonExpandedHeader: .init(labelId: labelId, message: message, user: user),
            bannerViewModel: banner(labelId: labelId, message: message, user: user),
            attachments: attachments(message: message)
        )

        return .init(labelId: labelId, message: message, user: user, childViewModels: childViewModels, internetStatusProvider: InternetConnectionStatusProvider(), isDarkModeEnableClosure: isDarkModeEnableClosure)
    }

    private func messageBody(message: MessageEntity,
                             user: UserManager,
                             isDarkModeEnableClosure: @escaping () -> Bool) -> NewMessageBodyViewModel {
        .init(
            message: message,
            messageDataProcessor: user.messageService,
            userAddressUpdater: user,
            shouldAutoLoadRemoteImages: user.userinfo.showImages.contains(.remote),
            shouldAutoLoadEmbeddedImages: user.userinfo.showImages.contains(.embedded),
            internetStatusProvider: InternetConnectionStatusProvider(),
            isDarkModeEnableClosure: isDarkModeEnableClosure,
            linkConfirmation: user.userinfo.linkConfirmation
        )
    }

    private func banner(labelId: LabelID, message: MessageEntity, user: UserManager) -> BannerViewModel {
        let unsubscribeService = UnsubscribeService(
            labelId: labelId,
            apiService: user.apiService,
            messageDataService: user.messageService,
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
            message: message,
            shouldAutoLoadRemoteContent: user.userinfo.showImages.contains(.remote),
            expirationTime: message.expirationTime,
            shouldAutoLoadEmbeddedImage: user.userinfo.showImages.contains(.embedded),
            unsubscribeService: unsubscribeService,
            markLegitimateService: markLegitimateService,
            receiptService: receiptService
        )
    }

    private func attachments(message: MessageEntity) -> AttachmentViewModel {
        let attachments: [AttachmentInfo] = message.attachments.map(AttachmentNormal.init)
        return .init(attachments: attachments)
    }

}
