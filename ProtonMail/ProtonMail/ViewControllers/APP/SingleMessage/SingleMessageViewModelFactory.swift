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
    private let components = SingleMessageComponentsFactory()

    func createViewModel(
        context: SingleMessageContentViewContext,
        user: UserManager,
        internetStatusProvider: InternetConnectionStatusProvider,
        isDarkModeEnableClosure: @escaping () -> Bool
    ) -> SingleMessageContentViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                message: context.message,
                user: user,
                isDarkModeEnableClosure: isDarkModeEnableClosure
            ),
            nonExpandedHeader: .init(labelId: context.labelId, message: context.message, user: user),
            bannerViewModel: components.banner(labelId: context.labelId, message: context.message, user: user),
            attachments: components.attachments(message: context.message)
        )
        return .init(
            context: context,
            childViewModels: childViewModels,
            user: user,
            internetStatusProvider: internetStatusProvider
        )
    }

}

class SingleMessageViewModelFactory {
    private let components = SingleMessageComponentsFactory()

    func createViewModel(labelId: LabelID,
                         message: MessageEntity,
                         user: UserManager,
                         isDarkModeEnableClosure: @escaping () -> Bool) -> SingleMessageViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                message: message,
                user: user,
                isDarkModeEnableClosure: isDarkModeEnableClosure
            ),
            nonExpandedHeader: .init(labelId: labelId, message: message, user: user),
            bannerViewModel: components.banner(labelId: labelId, message: message, user: user),
            attachments: components.attachments(message: message)
        )

        return .init(
            labelId: labelId,
            message: message,
            user: user,
            childViewModels: childViewModels,
            internetStatusProvider: InternetConnectionStatusProvider()
        )
    }

}

class SingleMessageComponentsFactory {

    func messageBody(message: MessageEntity,
                             user: UserManager,
                             isDarkModeEnableClosure: @escaping () -> Bool) -> NewMessageBodyViewModel {
        .init(
            message: message,
            messageDataProcessor: user.messageService,
            userAddressUpdater: user,
            shouldAutoLoadRemoteImages: user.userInfo.showImages.contains(.remote),
            shouldAutoLoadEmbeddedImages: user.userInfo.showImages.contains(.embedded),
            internetStatusProvider: InternetConnectionStatusProvider(),
            isDarkModeEnableClosure: isDarkModeEnableClosure,
            linkConfirmation: user.userInfo.linkConfirmation
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
        return .init(
            message: message,
            shouldAutoLoadRemoteContent: user.userInfo.showImages.contains(.remote),
            expirationTime: message.expirationTime,
            shouldAutoLoadEmbeddedImage: user.userInfo.showImages.contains(.embedded),
            unsubscribeService: unsubscribeService,
            markLegitimateService: markLegitimateService,
            receiptService: receiptService
        )
    }

    func attachments(message: MessageEntity) -> AttachmentViewModel {
        let attachments: [AttachmentInfo] = message.attachments.map(AttachmentNormal.init)
        return .init(attachments: attachments)
    }

}
