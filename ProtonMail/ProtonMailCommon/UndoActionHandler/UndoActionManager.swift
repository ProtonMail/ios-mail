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

protocol UndoActionHandlerBase: AnyObject {
    func showUndoAction(token: UndoTokenData, title: String)
}

protocol UndoActionManagerProtocol {
    func addUndoToken(_ token: UndoTokenData, undoActionType: UndoAction?)
    func register(handler: UndoActionHandlerBase)
    func sendUndoAction(token: UndoTokenData, completion: ((Bool) -> Void)?)
    func calculateUndoActionBy(labelID: String) -> UndoAction?
    func addTitleWithAction(title: String, action: UndoAction)
}

enum UndoAction: Equatable {
    case spam
    case trash
    case archive
    case custom(String)
}

final class UndoActionManager: UndoActionManagerProtocol {

    enum Const {
        // The time we wait for the undo action token arraived.
        // Once the time passed the threshold, we do not show the undo action banner.
        static let delayThreshold: TimeInterval = 4.0
    }

    struct UndoModel {
        let action: UndoAction
        let title: String
        let bannerDisplayTime: Date
    }

    let apiService: APIService
    private(set) weak var handler: UndoActionHandlerBase? {
        didSet {
            undoTitles.removeAll()
        }
    }
    let fetchEventClosure: (() -> Void)?

    private(set) var undoTitles: [UndoModel] = []

    init(apiService: APIService, fetchEventClosure: (() -> Void)?) {
        self.apiService = apiService
        self.fetchEventClosure = fetchEventClosure
    }

    /// Tirgger the handler to display the undo action banner if it is registered.
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
                self?.fetchEventClosure?()
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
