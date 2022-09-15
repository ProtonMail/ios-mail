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
        isDarkModeEnableClosure: @escaping () -> Bool,
        goToDraft: @escaping (MessageID) -> Void
    ) -> SingleMessageContentViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                message: context.message,
                user: user,
                isDarkModeEnableClosure: isDarkModeEnableClosure
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
                     isDarkModeEnableClosure: isDarkModeEnableClosure,
                     goToDraft: goToDraft)
    }

}

class SingleMessageViewModelFactory {
    private let components = SingleMessageComponentsFactory()

    func createViewModel(labelId: LabelID,
                         message: MessageEntity,
                         user: UserManager,
                         systemUpTime: SystemUpTimeProtocol,
                         isDarkModeEnableClosure: @escaping () -> Bool,
                         goToDraft: @escaping (MessageID) -> Void) -> SingleMessageViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: components.messageBody(
                message: message,
                user: user,
                isDarkModeEnableClosure: isDarkModeEnableClosure
            ),
            nonExpandedHeader: .init(isScheduledSend: message.isScheduledSend),
            bannerViewModel: components.banner(labelId: labelId, message: message, user: user),
            attachments: .init()
        )
        return .init(
            labelId: labelId,
            message: message,
            user: user,
            childViewModels: childViewModels,
            internetStatusProvider: InternetConnectionStatusProvider(),
            systemUpTime: systemUpTime,
            isDarkModeEnableClosure: isDarkModeEnableClosure,
			goToDraft: goToDraft
        )
    }

}

class SingleMessageComponentsFactory {

    func messageBody(message: MessageEntity,
                             user: UserManager,
                             isDarkModeEnableClosure: @escaping () -> Bool) -> NewMessageBodyViewModel {
        return .init(
            message: message,
            internetStatusProvider: InternetConnectionStatusProvider(),
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
        return .init(shouldAutoLoadRemoteContent: user.userInfo.showImages.contains(.remote),
                     expirationTime: message.expirationTime,
                     shouldAutoLoadEmbeddedImage: user.userInfo.showImages.contains(.embedded),
                     unsubscribeActionHandler: unsubscribeService,
                     markLegitimateActionHandler: markLegitimateService,
                     receiptActionHandler: receiptService,
                     weekStart: user.userInfo.weekStartValue,
                     urlOpener: UIApplication.shared)
    }
}
