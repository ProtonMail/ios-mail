//
//  LabelboxViewModelImpl.swift
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

class FolderboxViewModelImpl : MailboxViewModel {
    private let label : Label
    init(label : Label) {
        self.label = label
        super.init(labelID: self.label.labelID)
    }
    
    override func showLocation () -> Bool {
        return true
    }
    
    override func ignoredLocationTitle() -> String {
        return self.label.exclusive ? self.label.name : ""
    }
    
    open func stayAfterAction () -> Bool {
        if label.exclusive {
            return false
        }
        return true
    }
    
    override var localizedNavigationTitle: String {
        return self.label.name
    }
    
    override func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        return action.description;
    }
    
    open override func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        if label.exclusive {
            return false
        }
        return true
    }
    
    open override func deleteMessage(_ msg: Message) -> SwipeResponse {
        //TODO::fix me
//        if label.exclusive {
//            msg.removeFromFolder(current: label, location: .trash, keepSent: true)
//            msg.needsUpdate = true
//            msg.location = .trash
//
//            if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
//                PMLog.D(" error: \(error)")
//            }
//            return .showGeneral
//
//        } else {
//            msg.removeLocationFromLabels(currentlocation: msg.location, location: .trash, keepSent: true)
//            msg.needsUpdate = true
//            msg.location = .trash
//            if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
//                PMLog.D(" error: \(error)")
//            }
            return .showUndo
//        }
        
    }
    
    open override func archiveMessage(_ msg: Message) -> SwipeResponse {
        //TODO::fix me
//        self.updateBadgeNumberWhenMove(msg, to: .archive)
//        if label.exclusive {
//            msg.removeFromFolder(current: label, location: .archive, keepSent: true)
//            msg.needsUpdate = true
//            msg.location = .archive
//            if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
//                PMLog.D(" error: \(error)")
//            }
//            return .showGeneral
//        } else {
//            msg.removeLocationFromLabels(currentlocation: msg.location, location: .archive, keepSent: true)
//            msg.needsUpdate = true
//            msg.location = .archive
//            if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
//                PMLog.D("error: \(error)")
//            }
            return .showUndo
//        }
    }
    
    open override func spamMessage(_ msg: Message) -> SwipeResponse {
        //TODO::fix me
//        self.updateBadgeNumberWhenMove(msg, to: .spam)
//
//        if label.exclusive {
//            msg.removeFromFolder(current: label, location: .spam, keepSent: true)
//            msg.needsUpdate = true
//            msg.location = .spam
//            if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
//                PMLog.D(" error: \(error)")
//            }
//            return .showGeneral
//        } else {
//            msg.removeLocationFromLabels(currentlocation: msg.location, location: .spam, keepSent: true)
//            msg.needsUpdate = true
//            msg.location = .spam
//            if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
//                PMLog.D("error: \(error)")
//            }
            return .showUndo
//        }
    }
}
