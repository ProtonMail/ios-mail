//
//  MailboxViewModel.swift
//  ProtonMail - Created on 8/15/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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


class MailboxViewModel {
    private let labelID : String
    /// message service
    private let messageService : MessageDataService
    private let pushService : PushNotificationService
    /// fetch controller
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    /// local message for rating
    private var ratingMessage : Message?
    
    ///
    var selectedMessageIDs: NSMutableSet = NSMutableSet()
    
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
        guard self.fetchedResultsController?.numberOfSections() > index.section else {
            return nil
        }
        guard self.fetchedResultsController?.numberOfRows(in: index.section) > index.row else {
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
        guard self.fetchedResultsController?.numberOfSections() > index.section else {
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
    func selectedMessages() -> [Message] {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selectedMessageIDs)
            do {
                if let messages = try context.fetch(fetchRequest) as? [Message] {
                    return messages;
                }
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
            }
        }
        return [Message]();
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
    
    
    func move(from messages: [Message], to location: Message.Location) {
        for msg in messages {
            if let context = msg.managedObjectContext {
                switch location {
                case .inbox:
                    
                    break
                    
                case .starred:
                    // action: MessageAction =  ? .star : .unstar
                   // self.messageService.queue(msg, action: action)
                    break
                default:
                    break
                }
                
                
            }
        }
    }
    
    func move(from index: IndexPath, to location: Message.Location) {
        guard let message = self.item(index: index) else {
            return
        }
        
        self.move(from: message, to: location)
    }
    
    
    func move(from message: Message, to location: Message.Location) {
        

        
//            let action: MessageAction = message.unRead ? .unread : .read
//            self.queue(message, action: action)
//        }
    }
    
    //        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isStarred, handler: { message in
    //            if message.needsUpdate {
    //                let action: MessageAction = message.isStarred ? .star : .unstar
    //                self.queue(message, action: action)
    //            }
    //        })
    
        //call api here. better to cache it.
        //        messageService
        //        self.updateBadgeNumberWhenMove(msg, to: .archive)
        //        message.removeLocationFromLabels(currentlocation: msg.location, location: .archive, keepSent: true)
        //        msg.needsUpdate = true
        //        msg.location = .archive
        //        if let context = msg.managedObjectContext {
        //            context.perform {
        //                if let error = context.saveUpstreamIfNeeded() {
        //                    PMLog.D("error: \(error)")
        //                }
        //            }
        //        }
        //let currentLabels = message.labels

//    fileprivate func setupMessageMonitoring() {
//
//        //TODO:: double check
//        //        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.locationNumber, handler: { message in
//        //            if message.needsUpdate {
//        //                if let action = message.location.moveAction {
//        //                    self.queue(message, action: action)
//        //                } else {
//        //                    PMLog.D(" \(message.messageID) move to \(message.location) was not a user initiated move.")
//        //                }
//        //            }
//        //        })
//        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.unRead, handler: { message in
//            if message.needsUpdate {
//                let action: MessageAction = message.unRead ? .unread : .read
//                self.queue(message, action: action)
//            }
//        })
//
//        //        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isStarred, handler: { message in
//        //            if message.needsUpdate {
//        //                let action: MessageAction = message.isStarred ? .star : .unstar
//        //                self.queue(message, action: action)
//        //            }
//        //        })
//    }
    
    func label(on index: IndexPath, with labelID: String) {
        guard let message = self.item(index: index) else {
            return
        }
        
        // call api here. better to cache it.
        //        messageService
        //        self.updateBadgeNumberWhenMove(msg, to: .archive)
        //        message.removeLocationFromLabels(currentlocation: msg.location, location: .archive, keepSent: true)
        //        msg.needsUpdate = true
        //        msg.location = .archive
        //        if let context = msg.managedObjectContext {
        //            context.perform {
        //                if let error = context.saveUpstreamIfNeeded() {
        //                    PMLog.D("error: \(error)")
        //                }
        //            }
        //        }
    }
    
    
    func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        fatalError("This method must be overridden")
    }
    
    func deleteMessage(_ msg: Message) -> SwipeResponse {
        fatalError("This method must be overridden")
    }
    
    func archiveMessage(_ msg: Message) -> SwipeResponse {
        //TODO:: fixme
        //        self.updateBadgeNumberWhenMove(msg, to: .archive)
        //        msg.removeLocationFromLabels(currentlocation: msg.location, location: .archive, keepSent: true)
        //        msg.needsUpdate = true
        //        msg.location = .archive
        //        if let context = msg.managedObjectContext {
        //            context.perform {
        //                if let error = context.saveUpstreamIfNeeded() {
        //                    PMLog.D("error: \(error)")
        //                }
        //            }
        //        }
        return .showUndo
    }
    
    func spamMessage(_ msg: Message) -> SwipeResponse {
        //TODO:: fixme
        //        self.updateBadgeNumberWhenMove(msg, to: .spam)
        //        msg.removeLocationFromLabels(currentlocation: msg.location, location: .spam, keepSent: true)
        //        msg.needsUpdate = true
        //        msg.location = .spam
        //        if let context = msg.managedObjectContext {
        //            context.perform {
        //                if let error = context.saveUpstreamIfNeeded() {
        //                    PMLog.D("error: \(error)")
        //                }
        //            }
        //        }
        return .showUndo
    }
    
    func star(_ msg: Message) -> SwipeResponse{
        //TODO:: fixme
        //        self.updateBadgeNumberWhenMove(msg, to: .starred)
        //        msg.setLabelLocation(.starred)
        //        if let context = msg.managedObjectContext {
        //            context.perform {
        //                if let error = context.saveUpstreamIfNeeded() {
        //                    PMLog.D("error: \(error)")
        //                }
        //            }
        //        }
        //        //TODO:: add queue
        return .nothing
    }
    
    func starMessage(_ msg: Message) -> SwipeResponse {
        //        self.updateBadgeNumberWhenMove(msg, to: .starred)
        //        msg.setLabelLocation(.starred)
        //        msg.isStarred = true
        //        msg.needsUpdate = true
        //        if let context = msg.managedObjectContext {
        //            context.perform {
        //                if let error = context.saveUpstreamIfNeeded() {
        //                    PMLog.D("error: \(error)")
        //                }
        //            }
        //        }
        return .nothing
    }
    
    func unreadMessage(_ msg: Message) -> SwipeResponse {
        guard msg.unRead == false else {
            return .nothing
        }
        
        self.updateBadgeNumberWhenRead(msg, unRead: true)
        msg.unRead = true
        msg.needsUpdate = true
        if let context = msg.managedObjectContext {
            context.perform {
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
        }
        return .nothing
    }
    
    func updateBadgeNumberWhenMove(_ message : Message, to : String) {
        //TODO:: fix me
        //        let fromLocation = message.location
        //        let toLocation = to
        //
        //        if toLocation == .starred && message.isStarred {
        //            return
        //        }
        //
        //        var fromCount = lastUpdatedStore.UnreadCountForKey(fromLocation)
        //        var toCount = lastUpdatedStore.UnreadCountForKey(toLocation)
        //
        //        let offset = message.unRead ? 1 : 0
        //
        //        if toLocation != .starred {
        //            fromCount = fromCount + (-1 * offset)
        //            if fromCount < 0 {
        //                fromCount = 0
        //            }
        //            lastUpdatedStore.updateUnreadCountForKey(fromLocation, count: fromCount)
        //        }
        //
        //        if fromLocation != .starred {
        //            toCount = toCount + offset
        //            if toCount < 0 {
        //                toCount = 0
        //            }
        //            lastUpdatedStore.updateUnreadCountForKey(toLocation, count: toCount)
        //        }
        //
        //        if fromLocation == .inbox {
        //            UIApplication.setBadge(badge: fromCount)
        //            //UIApplication.shared.applicationIconBadgeNumber = fromCount
        //        }
        //        if toLocation == .inbox {
        //            UIApplication.setBadge(badge: toCount)
        //            //UIApplication.shared.applicationIconBadgeNumber = toCount
        //        }
    }
    
    func updateBadgeNumberWhenRead(_ message : Message, unRead : Bool) {
        //TODO:: fix me
        //        let location = message.location
        //
        //        if message.unRead == unRead {
        //            return
        //        }
        //        var count = lastUpdatedStore.UnreadCountForKey(location)
        //        count = count + (unRead ? 1 : -1)
        //        if count < 0 {
        //            count = 0
        //        }
        //        lastUpdatedStore.updateUnreadCountForKey(location, count: count)
        //
        //        if message.isStarred {
        //            var staredCount = lastUpdatedStore.UnreadCountForKey(.starred)
        //            staredCount = staredCount + (unRead ? 1 : -1)
        //            if staredCount < 0 {
        //                staredCount = 0
        //            }
        //            lastUpdatedStore.updateUnreadCountForKey(.starred, count: staredCount)
        //        }
        //        if location == .inbox {
        //            UIApplication.setBadge(badge: count)
        //            //UIApplication.shared.applicationIconBadgeNumber = count
        //        }
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
    
    //    func currentLocation() -> ExclusiveLabel? {
    //        return nil
    //    }
    
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
}
