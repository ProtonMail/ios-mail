//
//  ComposeSaveHintPortocol.swift
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

import Foundation
import ProtonCore_UIFoundations

protocol ComposeSaveHintProtocol: UIViewController {
    func removeDraftSaveHintBanner()
    func showDraftSaveHintBanner(cache: UserCachedStatus,
                                 messageService: MessageDataService,
                                 coreDataContextProvider: CoreDataContextProviderProtocol)
    func showDraftMoveToTrashBanner(messages: [Message],
                                    cache: UserCachedStatus,
                                    messageService: MessageDataService)
    func showDraftRestoredBanner(cache: UserCachedStatus)
    func showMessageSendingHintBanner()
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
              let _ = manager.users.first(where: { $0.userinfo.userId == user.userinfo.userId }),
              let messageID = cache.lastDraftMessageID else { return }
        let messages = messageService.fetchMessages(withIDs: [messageID], in: coreDataContextProvider.mainContext)

        let banner = PMBanner(message: LocalString._composer_draft_saved, style: TempPMBannerNewStyle.info)
        banner.addButton(text: LocalString._menu_trash_title) { [weak self] _ in
            messageService.move(messages: messages.map(MessageEntity.init),
                                from: [LabelLocation.draft.labelID],
                                to: LabelLocation.trash.labelID)
            banner.dismiss(animated: false)
            self?.showDraftMoveToTrashBanner(messages: messages,
                                             cache: cache,
                                             messageService: messageService)
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

    func showDraftMoveToTrashBanner(messages: [Message],
                                    cache: UserCachedStatus,
                                    messageService: MessageDataService) {
        let banner = PMBanner(message: LocalString._composer_draft_moved_to_trash,
                              style: TempPMBannerNewStyle.info)
        banner.addButton(text: LocalString._messages_undo_action) { [weak self] _ in
            messageService.move(messages: messages.map(MessageEntity.init),
                                from: [LabelLocation.trash.labelID],
                                to: LabelLocation.draft.labelID)
            banner.dismiss(animated: false)
            self?.showDraftRestoredBanner(cache: cache)
        }
        banner.show(at: getPosition(), on: self)
    }

    func showDraftRestoredBanner(cache: UserCachedStatus) {
        // _composer_draft_restored
        let banner = PMBanner(message: LocalString._composer_draft_restored, style: TempPMBannerNewStyle.info)
        banner.show(at: getPosition(), on: self)
    }

    func showMessageSendingHintBanner() {
        let banner = PMBanner(message: LocalString._messages_sending_message, style: TempPMBannerNewStyle.info)
        banner.show(at: getPosition(), on: self, ignoreKeyboard: true)
    }

    private func getPosition() -> PMBannerPosition {
        let position: PMBannerPosition
        if let _ = self as? ConversationViewController {
            position = .bottomCustom(.init(top: .infinity, left: 8, bottom: 64, right: 8))
        } else {
            position = .bottom
        }
        return position
    }
}
