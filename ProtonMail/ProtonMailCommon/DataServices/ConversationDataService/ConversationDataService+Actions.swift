//
//  ConversationDataService+Actions.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
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

extension ConversationDataService {
    func deleteConversations(with conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationDeleteRequest(conversationIDs: conversationIDs, labelID: labelID)
        self.apiService.exec(route: request) { (task, response: ConversationDeleteResponse) in
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

    func markAsRead(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationReadRequest(conversationIDs: conversationIDs)
        self.apiService.exec(route: request) { (task, response: ConversationReadResponse) in
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

    func markAsUnread(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationUnreadRequest(conversationIDs: conversationIDs, labelID: labelID)
        self.apiService.exec(route: request) { (task, response: ConversationUnreadResponse) in
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

    func label(conversationIDs: [String],
               as labelID: String,
               isSwipeAction: Bool,
               completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationLabelRequest(conversationIDs: conversationIDs, labelID: labelID)
        self.apiService.exec(route: request) { [weak self] (task, response: ConversationLabelResponse) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            if let undoTokenData = response.undoTokenData {
                let type = self?.undoActionManager.calculateUndoActionBy(labelID: labelID)
                self?.undoActionManager.addUndoToken(undoTokenData,
                                                     undoActionType: type)
            }
            completion?(.success(()))
        }
    }

    func unlabel(conversationIDs: [String],
                 as labelID: String,
                 isSwipeAction: Bool,
                 completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationUnlabelRequest(conversationIDs: conversationIDs, labelID: labelID)
        self.apiService.exec(route: request) { [weak self] (task, response: ConversationUnlabelResponse) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            if let undoTokenData = response.undoTokenData {
                let type = self?.undoActionManager.calculateUndoActionBy(labelID: labelID)
                self?.undoActionManager.addUndoToken(undoTokenData,
                                                     undoActionType: type)
            }
            completion?(.success(()))
        }
    }

    func move(conversationIDs: [String],
              from previousFolderLabel: String,
              to nextFolderLabel: String,
              isSwipeAction: Bool,
              completion: ((Result<Void, Error>) -> Void)?) {
        let conversations = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs), in: coreDataService.operationContext)
        let labelAction = { [weak self] in
            guard !nextFolderLabel.isEmpty else {
                completion?(.failure(ConversationError.emptyLabel))
                return
            }
            self?.label(conversationIDs: conversations.map(\.conversationID), as: nextFolderLabel, isSwipeAction: isSwipeAction, completion: completion)
        }
        guard !previousFolderLabel.isEmpty else {
            labelAction()
            return
        }
        unlabel(conversationIDs: conversations.map(\.conversationID), as: previousFolderLabel, isSwipeAction: isSwipeAction) { result in
            switch result {
            case .success:
                labelAction()
            case .failure:
                break
            }
        }
    }
}
