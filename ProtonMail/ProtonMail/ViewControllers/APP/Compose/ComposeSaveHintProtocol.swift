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
import ProtonCoreUIFoundations
import UIKit

protocol ComposeSaveHintProtocol: UIViewController {
    func removeDraftSaveHintBanner()
    func showDraftSaveHintBanner(cache: UserCachedStatusProvider,
                                 messageService: MessageDataService,
                                 coreDataContextProvider: CoreDataContextProviderProtocol)
    func showMessageSendingHintBanner(messageID: MessageID,
                                      messageDataService: MessageDataProcessProtocol)
    func showMessageSchedulingHintBanner(messageID: MessageID)
}

extension ComposeSaveHintProtocol {
    func removeDraftSaveHintBanner() {
        PMBanner.dismissAll(on: self)
    }

    func showDraftSaveHintBanner(cache: UserCachedStatusProvider,
                                 messageService: MessageDataService,
                                 coreDataContextProvider: CoreDataContextProviderProtocol) {
        // If the users doesn't contain user that means the user is logged out
        // Shouldn't show the banner
        guard let user = messageService.parent,
              let manager = user.parentManager,
              manager.users.contains(where: { $0.userInfo.userId == user.userInfo.userId }),
              let messageID = cache.lastDraftMessageID else { return }
        let banner = PMBanner(
            message: LocalString._composer_draft_saved,
            style: PMBannerNewStyle.info,
            bannerHandler: PMBanner.dismiss
        )
        banner.addButton(text: LocalString._general_discard) { [weak self] _ in
            let messages = coreDataContextProvider.read { context in
                return messageService.fetchMessages(withIDs: [messageID], in: context).map(MessageEntity.init)
            }
            messageService.delete(messages: messages, label: LabelLocation.draft.labelID)
            self?.showDiscardedBanner()
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

    func showDiscardedBanner() {
        let banner = PMBanner(
            message: LocalString._general_discarded,
            style: PMBannerNewStyle.info,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: getPosition(), on: self, ignoreKeyboard: true)
    }

    func showMessageSendingHintBanner(messageID: MessageID,
                                      messageDataService: MessageDataProcessProtocol) {
        let internetConnection = InternetConnectionStatusProvider.shared
        guard internetConnection.status != .notConnected else {
            self.showMessageSendingOfflineHintBanner(messageID: messageID, messageDataService: messageDataService)
            return
        }
        typealias Key = PMBanner.UserInfoKey
        let userInfo: [AnyHashable: Any] = [Key.type.rawValue: Key.sending.rawValue,
                                            Key.messageID.rawValue: messageID.rawValue]
        let banner = PMBanner(
            message: LocalString._messages_sending_message,
            style: PMBannerNewStyle.info,
            userInfo: userInfo,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: getPosition(), on: self, ignoreKeyboard: true)
    }

    func showMessageSchedulingHintBanner(messageID: MessageID) {
        typealias Key = PMBanner.UserInfoKey
        let userInfo: [AnyHashable: Any] = [Key.type.rawValue: Key.sending.rawValue,
                                            Key.messageID.rawValue: messageID.rawValue]
        let banner = PMBanner(
            message: LocalString._scheduling_message_title,
            style: PMBannerNewStyle.info,
            dismissDuration: TimeInterval.greatestFiniteMagnitude,
            userInfo: userInfo,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: getPosition(), on: self, ignoreKeyboard: true)
    }

    private func showMessageSendingOfflineHintBanner(
        messageID: MessageID,
        messageDataService: MessageDataProcessProtocol
    ) {
        let title = LocalString._message_queued_for_sending
        let banner = PMBanner(message: title,
                              style: PMBannerNewStyle.info,
                              bannerHandler: PMBanner.dismiss)
        banner.addButton(text: LocalString._general_cancel_button) { banner in
            banner.dismiss()
            messageDataService.cancelQueuedSendingTask(messageID: messageID)
        }
        banner.show(at: getPosition(), on: self, ignoreKeyboard: true)
    }

    private func getPosition() -> PMBannerPosition {
        let position: PMBannerPosition
        if self is ConversationViewController ||
            self is SingleMessageViewController ||
            String(describing: self).contains(check: "PagesViewController") {
            position = .bottomCustom(.init(top: .infinity, left: 8, bottom: 64, right: 8))
        } else {
            position = .bottom
        }
        return position
    }
}
