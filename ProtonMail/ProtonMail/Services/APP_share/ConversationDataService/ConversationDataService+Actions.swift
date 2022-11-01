//
//  ConversationDataService+Actions.swift
//  Proton Mail
//
//
//  Copyright (c) 2020 Proton AG
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

import ProtonCore_Networking

extension ConversationDataService {
    func deleteConversations(with conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationDeleteRequest(conversationIDs: conversationIDs.map(\.rawValue), labelID: labelID.rawValue)
        self.apiService.exec(route: request, responseObject: ConversationDeleteResponse()) { (task, response) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }

            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(()))
        }
    }

    func markAsRead(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationReadRequest(conversationIDs: conversationIDs.map(\.rawValue))
        self.apiService.exec(route: request, responseObject: ConversationReadResponse()) { (task, response) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(()))
        }
    }

    func markAsUnread(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationUnreadRequest(conversationIDs: conversationIDs.map(\.rawValue), labelID: labelID.rawValue)
        self.apiService.exec(route: request, responseObject: ConversationUnreadResponse()) { (task, response) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }

            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(()))
        }
    }

    func label(
        conversationIDs: [ConversationID],
        as labelID: LabelID,
        isSwipeAction: Bool,
        completion: ((Result<Void, Error>) -> Void)?
    ) {
        labelActionBatchRequest(
            request: ConversationLabelRequest.self,
            response: ConversationLabelResponse.self,
            conversationIDs: conversationIDs,
            as: labelID,
            completion: completion
        )
    }

    func unlabel(
        conversationIDs: [ConversationID],
        as labelID: LabelID,
        isSwipeAction: Bool,
        completion: ((Result<Void, Error>) -> Void)?
    ) {
        labelActionBatchRequest(
            request: ConversationUnlabelRequest.self,
            response: ConversationUnlabelResponse.self,
            conversationIDs: conversationIDs,
            as: labelID,
            completion: completion
        )
    }

    func move(conversationIDs: [ConversationID],
              from previousFolderLabel: LabelID,
              to nextFolderLabel: LabelID,
              isSwipeAction: Bool,
              callOrigin: String?,
              completion: ((Result<Void, Error>) -> Void)?) {
        let labelAction = { [weak self] in
            guard !nextFolderLabel.rawValue.isEmpty else {
                completion?(.failure(ConversationError.emptyLabel))
                return
            }
            self?.label(conversationIDs: conversationIDs, as: nextFolderLabel, isSwipeAction: isSwipeAction, completion: completion)
        }
        guard !previousFolderLabel.rawValue.isEmpty else {
            labelAction()
            return
        }
        unlabel(conversationIDs: conversationIDs, as: previousFolderLabel, isSwipeAction: isSwipeAction) { result in
            switch result {
            case .success:
                labelAction()
            case .failure:
                break
            }
        }
    }

    private func labelActionBatchRequest<T, U>(
        request: T.Type,
        response: U.Type,
        conversationIDs: [ConversationID],
        as labelID: LabelID,
        completion: ((Result<Void, Error>) -> Void)?
    ) where T: ConversationLabelActionBatchableRequest, U: Response & UndoTokenResponseProtocol {
        let requests = conversationIDs
            .map(\.rawValue)
            .chunked(into: T.maxNumberOfConversations)
            .map({ T(conversationIDs: $0, labelID: labelID.rawValue) })

        let undoAction = undoActionManager.calculateUndoActionBy(labelID: labelID.rawValue)

        let group = DispatchGroup()
        var undoTokens = [String]()
        var requestError = [NSError]()
        requests.forEach { [unowned self] request in
            group.enter()
            self.apiService.exec(route: request, responseObject: U.init()) { [unowned self] (_, response) in
                self.serialQueue.sync {
                    if let undoTokenData = response.undoTokenData {
                        undoTokens.append(undoTokenData.token)
                    } else if let error = response.error {
                        requestError.append(error.toNSError)
                    } else {
                        requestError.append(NSError.protonMailError(1000, localizedDescription: "Parsing error"))
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            if let firstReturnedError = requestError.first {
                completion?(.failure(firstReturnedError))
                return
            }
            self?.undoActionManager.addUndoTokens(undoTokens, undoActionType: undoAction)
            completion?(.success(()))
        }
    }
}
