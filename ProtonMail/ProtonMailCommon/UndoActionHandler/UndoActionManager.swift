// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_UIFoundations

protocol UndoActionHandlerBase: UIViewController {
    var delaySendSeconds: Int { get }
    var composerPresentingVC: UIViewController? { get }

    func showUndoAction(token: UndoTokenData, title: String)
}

protocol UndoActionManagerProtocol {
    func addUndoToken(_ token: UndoTokenData, undoActionType: UndoAction?)
    func showUndoSendBanner(for messageID: MessageID)
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
    private let contextProvider: CoreDataContextProviderProtocol
    private var getEventFetching: () -> EventsFetching?
    private var getUserManager: () -> UserManager?
    private(set) weak var handler: UndoActionHandlerBase? {
        didSet {
            undoTitles.removeAll()
        }
    }

    private(set) var undoTitles: [UndoModel] = []

    init(
        apiService: APIService,
        contextProvider: CoreDataContextProviderProtocol,
        getEventFetching: @escaping () -> EventsFetching?,
        getUserManager: @escaping () -> UserManager?
    ) {
        self.apiService = apiService
        self.contextProvider = contextProvider
        self.getEventFetching = getEventFetching
        self.getUserManager = getUserManager
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
    func showUndoSendBanner(for messageID: MessageID) {
        guard let targetVC = self.handler else { return }

        typealias Key = PMBanner.UserInfoKey
        PMBanner
            .getBanners(in: targetVC)
            .filter {
                $0.userInfo?[Key.type.rawValue] as? String == Key.sending.rawValue &&
                $0.userInfo?[Key.messageID.rawValue] as? String == messageID.rawValue
            }
            .forEach { $0.dismiss(animated: false) }

        let delaySeconds = max(targetVC.delaySendSeconds, 1)
        let banner = PMBanner(message: LocalString._message_sent_ok_desc,
                              style: PMBannerNewStyle.info,
                              dismissDuration: TimeInterval(delaySeconds),
                              bannerHandler: PMBanner.dismiss)
        if delaySeconds > 1 {
            let buttonTitle = LocalString._messages_undo_action
            banner.addButton(text: buttonTitle) { [weak self, weak banner] _ in
                banner?.dismiss(animated: true)
                self?.undoSending(messageID: messageID) { isSuccess in
                    if isSuccess {
                        self?.showComposer(for: messageID)
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
                self?.getEventFetching()?.fetchEvents(labelID: labelID)
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
    // Call undo send api to cancel sent message
    // The undo send action is time sensitive, put in queue doesn't make sense
    func undoSending(messageID: MessageID, completion: ((Bool) -> Void)?) {
        let request = UndoSendRequest(messageID: messageID)
        apiService.exec(route: request) { [weak self] (result: Result<UndoSendResponse, ResponseError>) in
            switch result {
            case .success:
                let labelID = Message.Location.allmail.labelID
                self?.getEventFetching()?
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

    private func showComposer(for messageID: MessageID) {
        #if !APP_EXTENSION
            guard let message = message(id: messageID),
                  let user = getUserManager() else { return }

            let viewModel = ContainableComposeViewModel(
                msg: message,
                action: .openDraft,
                msgService: user.messageService,
                user: user,
                coreDataContextProvider: contextProvider
            )

            guard let presentingVC = self.handler?.composerPresentingVC else { return }
            let composer = ComposeContainerViewCoordinator(
                presentingViewController: presentingVC,
                editorViewModel: viewModel
            )
            composer.start()
        #endif
    }

    private func message(id messageID: MessageID) -> Message? {
        let context = contextProvider.mainContext
        return Message.messageForMessageID(messageID.rawValue, inManagedObjectContext: context)
    }
}
