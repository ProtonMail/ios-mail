//
//  NSError+Alert+Share.swift
//  Share - Created on 9/26/17.
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


extension NSError {
    static var errorOccuredNotification: NSNotification.Name {
        return NSNotification.Name("NSErrorOccured")
    }
    static var noErrorNotification: NSNotification.Name {
        return NSNotification.Name("NSErrorNoError")
    }
    
    public class func alertMessageSentToast() ->Void {
        NotificationCenter.default.post(name: NSError.noErrorNotification, object: nil, userInfo: ["text": LocalString._message_sent_ok_desc])
    }
    
    public func alertSentErrorToast() ->Void {
        NotificationCenter.default.post(name: NSError.errorOccuredNotification, object: nil, userInfo: ["text": "\(LocalString._message_sent_failed_desc): \(self.localizedDescription)"])
    }
    
    public class func alertLocalCacheErrorToast() ->Void {
        NotificationCenter.default.post(name: NSError.errorOccuredNotification, object: nil, userInfo: ["text": LocalString._message_draft_cache_is_broken])
    }
    
    public class func alertBadTokenToast() ->Void {
        NotificationCenter.default.post(name: NSError.errorOccuredNotification, object: nil, userInfo: ["text": LocalString._general_invalid_access_token])
    }
    
    public class func alertBadToken() {
        NotificationCenter.default.post(name: NSError.errorOccuredNotification, object: nil, userInfo: ["text": LocalString._general_invalid_access_token])
    }
    
    public class func alertUpdatedToast() ->Void {

    }
    
    public func alertErrorToast() ->Void {
        NotificationCenter.default.post(name: NSError.errorOccuredNotification, object: nil, userInfo: ["text": NSLocalizedString(localizedDescription, comment: "Title")])
    }
    
    public class func alertMessageSentErrorToast() ->Void {
        NotificationCenter.default.post(name: NSError.errorOccuredNotification, object: nil, userInfo: ["text": LocalString._messages_sending_failed_try_again])
    }
    
    public class func alertMessageSentError(details : String) -> Void {
        NotificationCenter.default.post(name: NSError.errorOccuredNotification, object: nil, userInfo: ["text": LocalString._messages_sending_failed_try_again + " " + details])
    }
    
    public class func alertSavingDraftError(details : String) -> Void {
        NotificationCenter.default.post(name: NSError.errorOccuredNotification, object: nil, userInfo: ["text": details])
    }
    
    
    public class func alertMessageSendingToast() ->Void {
        
    }
}
