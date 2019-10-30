//
//  MailboxViewModel.swift
//  ProtonMail - Created on 8/15/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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
import CoreData

enum SwipeResponse {
    case showUndo
    case nothing
    case showGeneral
}

class UndoMessage {
    var messageID : String
    var origLabels : String
    var newLabels : String
    
    //
    required init(msgID: String, origLabels : String, newLabels: String) {
        self.messageID  = msgID
        self.origLabels = origLabels
        self.newLabels  = newLabels
    }
}
extension MailboxViewModel: Codable {
    enum CodingKeys: CodingKey {
        case labelID
    }
    
    enum Errors: Error {
        case decoding
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.labelID, forKey: .labelID)
    }
}

class MailboxViewModel {
    internal let labelID : String
    /// message service
    internal let messageService : MessageDataService
    private let pushService : PushNotificationService
    /// fetch controller
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    /// local message for rating
    private var ratingMessage : Message?
    
    
    /// mailbox viewModel
    ///
    /// - Parameters:
    ///   - labelID: location id and labelid
    ///   - msgService: service instance
    init(labelID : String, msgService: MessageDataService, pushService: PushNotificationService) {
        self.labelID = labelID
        self.messageService = msgService
        self.pushService = pushService
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let label = try container.decode(String.self, forKey: .labelID)
        
        self.labelID = label
        self.messageService = sharedServices.get()
        self.pushService = sharedServices.get()
    }
    
    /// localized navigation title. overrride it or return label name
    var localizedNavigationTitle : String {
        get {
            return ""
        }
    }
    
    /// create a fetch controller with labelID
    ///
    /// - Returns: fetched result controller
    private func makeFetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchedResultsController = messageService.fetchedResults(by: self.labelID)
        if let fetchedResultsController = fetchedResultsController {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
            }
        }
        return fetchedResultsController
    }
    
    /// setup fetch controller
    ///
    /// - Parameter delegate: delegate from viewcontroller
    func setupFetchController(_ delegate: NSFetchedResultsControllerDelegate?) {
        self.fetchedResultsController = self.makeFetchController()
        self.fetchedResultsController?.delegate = delegate
    }
    
    /// reset delegate if fetch controller is valid
    func resetFetchedController() {
        if let controller = self.fetchedResultsController {
            controller.delegate = nil
            self.fetchedResultsController = nil
        }
    }

    
    ///Mark -- table view usesage
    
    /// get section cound
    ///
    /// - Returns: 
    func sectionCount() -> Int {
        return fetchedResultsController?.numberOfSections() ?? 0
    }
    
    /// get row count of a section
    ///
    /// - Parameter section: section index
    /// - Returns: row count
    func rowCount(section: Int) -> Int {
        return fetchedResultsController?.numberOfRows(in: section) ?? 0
    }
    
    /// get message item from a indexpath
    ///
    /// - Parameter index: table cell indexpath
    /// - Returns: message (nil)
    func item(index: IndexPath) -> Message? {
        guard !index.isEmpty, let sections = self.fetchedResultsController?.numberOfSections() else {
            return nil
        }
        guard sections > index.section else {
            return nil
        }
        
        guard let rows = self.fetchedResultsController?.numberOfRows(in: index.section) else {
            return nil
        }
        
        guard rows > index.row else {
            return nil
        }
        
        return fetchedResultsController?.object(at: index) as? Message
    }
    
    
    ///Mark -- operations
    
    /// clean up the rate/review items
    func cleanReviewItems() {
        if let context = fetchedResultsController?.managedObjectContext {
            context.perform {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
                fetchRequest.predicate = NSPredicate(format: "%K == 1", Message.Attributes.messageType)
                do {
                    if let messages = try context.fetch(fetchRequest) as? [Message] {
                        for msg in messages {
                            if msg.managedObjectContext != nil {
                                context.delete(msg)
                            }
                        }
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D("error: \(error)")
                        }
                    }
                } catch let ex as NSError {
                    PMLog.D("error: \(ex)")
                }
            }
        }
    }
    
    
    /// check if need to load more older messages
    ///
    /// - Parameter index: the current table index
    /// - Returns: yes or no
    func loadMore(index: IndexPath) -> Bool {
        guard let number = self.fetchedResultsController?.numberOfSections() else {
            return false
        }
        guard number > index.section else {
            return false
        }
        guard let total = self.fetchedResultsController?.numberOfRows(in: index.section) else {
            return false
        }
        if total - index.row <= 2 {
            return true
        }
        return false
    }
    
    /// the latest cache time of current location
    ///
    /// - Returns: location cache info
    func lastUpdateTime() -> UpdateTime {
        return lastUpdatedStore.labelsLastForKey(self.labelID)
    }
    
    
    /// process push
    func processCachedPush() {
        self.pushService.processCachedLaunchOptions()
    }
    
    ///
    func selectedMessages(selected: NSMutableSet) -> [Message] {
        return messageService.fetchMessages(withIDs: selected)
    }
    
    ///
    func message(by messageID: String) -> Message? {
        if let context = self.fetchedResultsController?.managedObjectContext {
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                return message
            }
        }
        return nil
    }
    ///
    func object(by object: NSManagedObjectID) -> Message? {
        if let obj = self.fetchedResultsController?.managedObjectContext.object(with: object) as? Message {
            return obj
        }
        return nil
    }
    
    func indexPath(by messageID: String) -> IndexPath? {
        guard let object = self.message(by: messageID),
            let index = self.fetchedResultsController?.indexPath(forObject: object) else
        {
            return nil
        }
        return index
    }
    
    /// rating index
    var ratingIndex : IndexPath? {
        get {
            if let msg = ratingMessage {
                if let indexPath = fetchedResultsController?.indexPath(forObject: msg) {
                    return indexPath
                }
            }
            return nil
        }
    }
    
    func isDrafts() -> Bool {
        return false
    }
    
    func isArchive() -> Bool {
        return false
    }
    
    func isDelete () -> Bool {
        return false
    }
    
    func showLocation () -> Bool {
        return false
    }
    
    func ignoredLocationTitle() -> String {
        return ""
    }
    
    func isCurrentLocation(_ l : Message.Location) -> Bool {
        return self.labelID == l.rawValue
    }
    
    func isSwipeActionValid(_ action: MessageSwipeAction) -> Bool {
        return true
    }
    
    func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        return false
    }
    
    func isShowEmptyFolder() -> Bool {
        return false
    }
    
    func emptyFolder() {
        
    }
    
    typealias CompletionBlock = APIService.CompletionBlock
    func fetchMessages(time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        messageService.fetchMessages(byLable: self.labelID, time: time, forceClean: foucsClean, completion: completion)
    }
    
    func fetchEvents(time: Int, notificationMessageID:String?, completion: CompletionBlock?) {
        messageService.fetchEvents(byLable: self.labelID, notificationMessageID: notificationMessageID, completion: completion)
    }
    
    /// fetch messages and reset events
    ///
    /// - Parameters:
    ///   - time: the latest mailbox cached time
    ///   - completion: aync complete handler
    func fetchMessageWithReset(time: Int, completion: CompletionBlock?) {
        messageService.fetchMessagesWithReset(byLabel: self.labelID, time: time, completion: completion)
    }
    
    /// get the cached notification message id
    var notificationMessageID : String? {
        get {
            return messageService.pushNotificationMessageID
        }
    }
    
    var notificationMessage : Message? {
        get {
            return messageService.messageFromPush()
        }
    }
    
    final func resetNotificationMessage() -> Void {
        messageService.pushNotificationMessageID = nil
    }
    
    /// this is a workaground for draft. somehow back from the background the fetch controller can't get the latest data. remove this when fix this issue
    ///
    /// - Returns: bool
    func reloadTable() -> Bool {
        return false
    }
    
    func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        fatalError("This method must be overridden")
    }

    func mark(IDs messageIDs : NSMutableSet, unread: Bool) {
        let messages = self.messageService.fetchMessages(withIDs: messageIDs)
        for msg in messages {
            messageService.mark(message : msg, unRead: unread)
        }
    }
    
    func mark(msg message : Message, unread: Bool = true) {
        messageService.mark(message : message, unRead: unread)
    }

    func label(IDs messageIDs : NSMutableSet, with labelID: String, apply: Bool) {
        let messages = self.messageService.fetchMessages(withIDs: messageIDs)
        for msg in messages {
            messageService.label(message: msg, label: labelID, apply: apply)
        }
    }
    
    func label(msg message : Message, with labelID: String, apply: Bool = true) {
        messageService.label(message: message, label: labelID, apply: apply)
    }
    
    func move(IDs messageIDs : NSMutableSet, to tLabel: String) {
        self.move(IDs: messageIDs, from: self.labelID, to: tLabel)
    }
    
    func move(IDs messageIDs : NSMutableSet, from fLabel: String, to tLabel: String) {
        let messages = self.messageService.fetchMessages(withIDs: messageIDs)
        for msg in messages {
            messageService.move(message: msg, from: fLabel, to: tLabel)
        }
    }
    
    func undo(_ undo: UndoMessage) {
        let messages = self.messageService.fetchMessages(withIDs: [undo.messageID])
        for msg in messages {
            messageService.move(message: msg, from: undo.newLabels, to: undo.origLabels)
        }
    }
    
    final func delete(IDs: NSMutableSet) {
        let messages = self.messageService.fetchMessages(withIDs: IDs)
        for msg in messages {
            let _ = self.delete(message: msg)
        }
    }
    
    final func delete(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            return self.delete(message: message)
        }
        return (.nothing, nil)
    }
    
    func delete(message: Message) -> (SwipeResponse, UndoMessage?) {
        if messageService.move(message: message, from: self.labelID, to: Message.Location.trash.rawValue) {
            return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, newLabels: Message.Location.trash.rawValue))
        }
        return (.nothing, nil)
    }
    
    func archive(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if messageService.move(message: message, from: self.labelID, to: Message.Location.archive.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, newLabels: Message.Location.archive.rawValue))
            }
        }
        return (.nothing, nil)
    }
    
    func spam(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if messageService.move(message: message, from: self.labelID, to: Message.Location.spam.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, newLabels: Message.Location.spam.rawValue))
            }
        }
        return (.nothing, nil)
    }
}
