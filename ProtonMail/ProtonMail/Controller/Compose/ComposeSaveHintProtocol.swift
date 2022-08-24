//
//  ComposeSaveHintPortocol.swift
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

import Foundation
import ProtonCore_UIFoundations

protocol ComposeSaveHintProtocol: UIViewController {
    func removeDraftSaveHintBanner()
    func showDraftSaveHintBanner(cache: UserCachedStatus,
                                 messageService: MessageDataService,
                                 coreDataContextProvider: CoreDataContextProviderProtocol)
    func showMessageSendingHintBanner(messageID: String,
                                      messageDataService: MessageDataProcessProtocol)
}

extension ComposeSaveHintProtocol {
    func removeDraftSaveHintBanner() {
        PMBanner.dismissAll(on: self)
    }

    func showDraftSaveHintBanner(cache: UserCachedStatus,
                                 messageService: MessageDataService,
                                 coreDataContextProvider: CoreDataContextProviderProtocol) {
        // If the users doesn't contain user that means the user is logged out
        // Shouldn't show the banner
        guard let user = messageService.parent,
              let manager = user.parentManager,
              manager.users.contains(where: { $0.userinfo.userId == user.userinfo.userId }),
              let messageID = cache.lastDraftMessageID else { return }
        let messages = messageService.fetchMessages(withIDs: [messageID], in: coreDataContextProvider.mainContext)

        let banner = PMBanner(
            message: LocalString._composer_draft_saved,
            style: TempPMBannerNewStyle.info,
            bannerHandler: PMBanner.dismiss
        )
        banner.addButton(text: LocalString._general_discard) { _ in
            messageService.delete(messages: messages.map(MessageEntity.init), label: LabelLocation.draft.labelID)
            banner.dismiss(animated: false)
        }
        banner.show(at: getPosition(), on: self, ignoreKeyboard: true)

        if let listVC = self as? MailboxViewController {
            // Since we ignore core data event when composer is presented
            // We need to refresh view when composer dismiss
            // Or the app could crash when user pull down to refresh
            // the display data and data source not compatible
            listVC.tableView.reloadData()
        }
    }

    func showMessageSendingHintBanner(messageID: String,
                                      messageDataService: MessageDataProcessProtocol) {
        let internetConnection = InternetConnectionStatusProvider()
        guard internetConnection.currentStatus != .notConnected else {
            self.showMessageSendingOfflineHintBanner(messageID: messageID, messageDataService: messageDataService)
            return
        }
        typealias Key = PMBanner.UserInfoKey
        let userInfo: [AnyHashable: Any] = [Key.type.rawValue: Key.sending.rawValue,
                                            Key.messageID.rawValue: messageID]
        let banner = PMBanner(
            message: LocalString._messages_sending_message,
            style: TempPMBannerNewStyle.info,
            userInfo: userInfo,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: getPosition(), on: self, ignoreKeyboard: true)
    }

    private func showMessageSendingOfflineHintBanner(
        messageID: String,
        messageDataService: MessageDataProcessProtocol
    ) {
        let title = LocalString._message_queued_for_sending
        let banner = PMBanner(message: title,
                              style: TempPMBannerNewStyle.info,
                              bannerHandler: PMBanner.dismiss)
        banner.addButton(text: LocalString._general_cancel_button) { banner in
            banner.dismiss()
            messageDataService.cancelQueuedSendingTask(messageID: messageID)
        }
        banner.show(at: getPosition(), on: self, ignoreKeyboard: true)
    }

    private func getPosition() -> PMBannerPosition {
        let position: PMBannerPosition
        if self is ConversationViewController {
            position = .bottomCustom(.init(top: .infinity, left: 8, bottom: 64, right: 8))
        } else {
            position = .bottom
        }
        return position
    }
}
