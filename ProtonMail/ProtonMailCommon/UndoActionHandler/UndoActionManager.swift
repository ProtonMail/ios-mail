// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_UIFoundations

protocol UndoActionHandlerBase: UIViewController {
    var delaySendSeconds: Int { get }

    func showUndoAction(token: UndoTokenData, title: String)
}

protocol UndoActionManagerProtocol {
    func addUndoToken(_ token: UndoTokenData, undoActionType: UndoAction?)
    func showUndoSendBanner(for messageID: String)
    func register(handler: UndoActionHandlerBase)
    func sendUndoAction(token: UndoTokenData, completion: ((Bool) -> Void)?)
    func calculateUndoActionBy(labelID: String) -> UndoAction?
    func addTitleWithAction(title: String, action: UndoAction)
}

enum UndoAction: Equatable {
    case send
    case spam
    case trash
    case archive
    case custom(String)
}

final class UndoActionManager: UndoActionManagerProtocol {

    enum Const {
        // The time we wait for the undo action token arrived.
        // Once the time passed the threshold, we do not show the undo action banner.
        static let delayThreshold: TimeInterval = 4.0
    }

    struct UndoModel {
        let action: UndoAction
        let title: String
        let bannerDisplayTime: Date
    }

    private let apiService: APIService
    private weak var eventFetch: EventsFetching?
    private(set) weak var handler: UndoActionHandlerBase? {
        didSet {
            undoTitles.removeAll()
        }
    }

    private(set) var undoTitles: [UndoModel] = []

    init(apiService: APIService, eventFetch: EventsFetching) {
        self.apiService = apiService
        self.eventFetch = eventFetch
    }

    /// Trigger the handler to display the undo action banner if it is registered.
    func addUndoToken(_ token: UndoTokenData, undoActionType: UndoAction?) {
        guard let type = undoActionType,
              let index = undoTitles.firstIndex(where: { $0.action == type }),
              let item = undoTitles[safe: index] else {
                  return
              }
        if Date().timeIntervalSince1970 - item.bannerDisplayTime.timeIntervalSince1970 < Const.delayThreshold {
            handler?.showUndoAction(token: token, title: item.title)
        }
        undoTitles.remove(at: index)
    }

    /// Trigger the handler to display the undo send banner
    func showUndoSendBanner(for messageID: String) {
        guard let targetVC = self.handler else { return }

        typealias Key = PMBanner.UserInfoKey
        PMBanner
            .getBanners(in: targetVC)
            .filter {
                $0.userInfo?[Key.type.rawValue] as? String == Key.sending.rawValue &&
                $0.userInfo?[Key.messageID.rawValue] as? String == messageID
            }
            .forEach { $0.dismiss(animated: false) }

        let delaySeconds = max(targetVC.delaySendSeconds, 1)
        let banner = PMBanner(message: LocalString._message_sent_ok_desc,
                              style: TempPMBannerNewStyle.info,
                              dismissDuration: TimeInterval(delaySeconds))
        if delaySeconds > 1 {
            let buttonTitle = LocalString._messages_undo_action
            banner.addButton(text: buttonTitle) { [weak self, weak banner] _ in
                banner?.dismiss(animated: true)
                self?.undoSending(messageID: messageID) { isSuccess in
                    if isSuccess {
                        self?.showUndoSendFinishBanner()
                    }
                }
            }
        }
        banner.show(at: .bottom, on: targetVC)
    }

    /// Register the current handler of undo action.
    func register(handler: UndoActionHandlerBase) {
        self.handler = handler
    }

    /// Add the displayed title and action of the banner to the cache in order to match with the undo token.
    func addTitleWithAction(title: String, action: UndoAction) {
        undoTitles.append(UndoModel(action: action, title: title, bannerDisplayTime: Date()))
    }

    func sendUndoAction(token: UndoTokenData, completion: ((Bool) -> Void)?) {
        let request = UndoActionRequest(token: token.token)
        apiService.exec(route: request) { [weak self] (result: Result<UndoActionResponse, ResponseError>) in
            switch result {
            case .success:
                let labelID = Message.Location.allmail.labelID
                self?.eventFetch?.fetchEvents(labelID: labelID)
                completion?(true)
            case .failure:
                completion?(false)
            }
        }
    }

    func calculateUndoActionBy(labelID: String) -> UndoAction? {
        var type: UndoAction?
        switch labelID {
        case Message.Location.trash.rawValue:
            type = .trash
        case Message.Location.archive.rawValue:
            type = .archive
        case Message.Location.spam.rawValue:
            type = .spam
        default:
            if !labelID.isEmpty &&
                Message.Location(rawValue: labelID) == nil {
                type = .custom(labelID)
            }
        }
        return type
    }
}

// MARK: Undo send
extension UndoActionManager {
    func showUndoSendFinishBanner() {
        guard let targetVC = self.handler else { return }
        let banner = PMBanner(message: LocalString._message_move_to_draft,
                              style: TempPMBannerNewStyle.info)
        banner.show(at: .bottom, on: targetVC)
    }

    // Call undo send api to cancel sent message
    // The undo send action is time sensitive, put in queue doesn't make sense
    func undoSending(messageID: String, completion: ((Bool) -> Void)?) {
        let request = UndoSendRequest(messageID: messageID)
        apiService.exec(route: request) { [weak self] (result: Result<UndoSendResponse, ResponseError>) in
            switch result {
            case .success:
                let labelID = Message.Location.allmail.labelID
                self?.eventFetch?
                    .fetchEvents(byLabel: labelID,
                                 notificationMessageID: nil,
                                 completion: { _, _, _ in
                        completion?(true)
                    })
            case .failure:
                completion?(false)
            }
        }
    }
}
