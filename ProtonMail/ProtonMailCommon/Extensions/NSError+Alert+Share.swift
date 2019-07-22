//
//  NSError+Alert+Share.swift
//  Share - Created on 9/26/17.
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
