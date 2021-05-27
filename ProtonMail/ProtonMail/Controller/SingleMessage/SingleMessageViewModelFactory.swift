//
//  SingleMessageViewModelFactory.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

class SingleMessageViewModelFactory {

    func createViewModel(labelId: String, message: Message, user: UserManager) -> SingleMessageViewModel {
        let childViewModels = SingleMessageChildViewModels(
            messageBody: messageBody(message: message, user: user),
            nonExpandedHeader: .init(labelId: labelId, message: message, user: user),
            bannerViewModel: banner(labelId: labelId, message: message, user: user),
            attachments: attachments(message: message)
        )

        return .init(labelId: labelId, message: message, user: user, childViewModels: childViewModels, internetStatusProvider: InternetConnectionStatusProvider())
    }

    private func messageBody(message: Message, user: UserManager) -> NewMessageBodyViewModel {
        .init(
            message: message,
            messageService: user.messageService,
            userManager: user,
            shouldAutoLoadRemoteImages: user.userinfo.showImages.contains(.remote),
            shouldAutoLoadEmbeddedImages: user.userinfo.showImages.contains(.embedded),
            internetStatusProvider: InternetConnectionStatusProvider()
        )
    }

    private func banner(labelId: String, message: Message, user: UserManager) -> BannerViewModel {
        let unsubscribeService = UnsubscribeService(
            labelId: labelId,
            apiService: user.apiService,
            messageDataService: user.messageService,
            eventsService: user.eventsService
        )
        let markLegitimateService = MarkLegitimateService(
            labelId: labelId,
            apiService: user.apiService,
            messageDataService: user.messageService,
            eventsService: user.eventsService
        )
        return .init(
            message: message,
            shouldAutoLoadRemoteContent: user.userinfo.showImages.contains(.remote),
            expirationTime: message.expirationTime,
            shouldAutoLoadEmbeddedImage: user.userinfo.showImages.contains(.embedded),
            unsubscribeService: unsubscribeService,
            markLegitimateService: markLegitimateService
        )
    }

    private func attachments(message: Message) -> AttachmentViewModel {
        let attachments: [AttachmentInfo] = message.attachments.compactMap { $0 as? Attachment }
            .map(AttachmentNormal.init) + (message.tempAtts ?? [])

        return .init(attachments: attachments)
    }

}
