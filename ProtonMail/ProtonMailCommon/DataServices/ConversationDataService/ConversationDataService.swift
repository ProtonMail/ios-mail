//
//  ConversationDataService.swift
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
import ProtonCore_Services

enum ReadState {
    case unread
    case read
}

protocol ConversationProvider {
    func fetchConversationCounts(addressId: String?, completion: @escaping ((Result<Void, Error>) -> Void))
    func fetchConversations(for label: String, beforeTimestamp: Int, unreadOnly: Bool, completion: @escaping ((Result<Void, Error>) -> Void))
    func fetchConversations(with ids: [String], completion: @escaping ((Result<Void, Error>) -> Void))
    func deleteConversation(with id: String, completion: @escaping ((Result<Void, Error>) -> Void))
    func mark(conversationIDs: [String], as state: ReadState, completion: @escaping ((Result<Void, Error>) -> Void))
    func label(conversationIDs: [String], as label: String, completion: @escaping ((Result<Void, Error>) -> Void))
    func unlabel(conversationIDs: [String], as label: String, completion: @escaping ((Result<Void, Error>) -> Void))

}

final class ConversationDataService: Service, ConversationProvider {
    private let apiService : APIService
    private let userID : String
    private let coreDataService: CoreDataService
    private let lastUpdatedStore: LastUpdatedStoreProtocol
    private weak var viewModeDataSource: ViewModeDataSource?
    private weak var queueManager: QueueManager?
    
    init(api: APIService,
         userID: String,
         coreDataService: CoreDataService,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         viewModeDataSource: ViewModeDataSource?,
         queueManager: QueueManager?) {
        self.apiService = api
        self.userID = userID
        self.coreDataService = coreDataService
        self.lastUpdatedStore = lastUpdatedStore
        self.queueManager = queueManager
    }

    func fetchConversationCounts(addressId: String?, completion: @escaping ((Result<Void, Error>) -> Void)) {
        fatalError()
    }
    
    func fetchConversations(for label: String, beforeTimestamp: Int, unreadOnly: Bool, completion: @escaping ((Result<Void, Error>) -> Void)) {
        fatalError()
    }
    
    func fetchConversations(with ids: [String], completion: @escaping ((Result<Void, Error>) -> Void)) {
        fatalError()
    }
    
    func deleteConversation(with id: String, completion: @escaping ((Result<Void, Error>) -> Void)) {
        fatalError()
    }
    
    func mark(conversationIDs: [String], as state: ReadState, completion: @escaping ((Result<Void, Error>) -> Void)) {
        fatalError()
    }
    
    func label(conversationIDs: [String], as label: String, completion: @escaping ((Result<Void, Error>) -> Void)) {
        fatalError()
    }
    
    func unlabel(conversationIDs: [String], as label: String, completion: @escaping ((Result<Void, Error>) -> Void)) {
        fatalError()
    }
}
