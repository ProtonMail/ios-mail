//
//  Analytics.swift
//  ProtonMail - Created on 30/11/2018.
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
import Sentry

class Analytics {
    typealias Event = Sentry.Event
    static var shared = Analytics()
    
    private var sentryEndpoint: String {
        #if Enterprise
            return "https://3f5b27555fa64b519002266dcdc7744c@api.protonmail.ch/reports/sentry/25"
        #else
            return "https://bcbe8b2a026848c4b139df228d088072@api.protonmail.ch/reports/sentry/7"
        #endif
    }
    
    func setup() {
        SentrySDK.start { (options) in
            options.dsn = self.sentryEndpoint
            #if DEBUG
            options.debug = true
            #endif
        }
    }
    
    func debug(message: Analytics.Events, extra: [String: Any],
               user: UserManager?=nil, file: String = #file,
               function: String = #function, line: Int = #line,
               column: Int = #column) {
        
        let appendDic = self.getAppendInfo(file, function, line, column)
        let event = Event(level: .debug)
        event.message = message.rawValue
        event.extra = extra + appendDic
        event.user = self.getUsesr(currentUser: user)
        SentrySDK.capture(event: event)
    }
    
    func error(message: Analytics.Events, error: Error, extra: [String: Any]=[:],
               user: UserManager?=nil, file: String = #file,
               function: String = #function, line: Int = #line,
               column: Int = #column) {
        
        let err = error as NSError
        let dic: [String: Any] = [
            "code" : err.code,
            "error_desc": err.description,
            "error_full": err.localizedDescription,
            "error_reason" : "\(String(describing: err.localizedFailureReason))"
        ]
        let appendDic = self.getAppendInfo(file, function, line, column)
        // todo assemble message
        let event = Event(level: .error)
        let _error = error as NSError
        event.message = "\(message.rawValue) - \(_error.code)"
        event.extra = extra + appendDic + dic
        event.user = self.getUsesr(currentUser: user)
        SentrySDK.capture(event: event)
    }
    
    func error(message: Analytics.Events, error: String, extra: [String: Any]=[:],
               user: UserManager?=nil, file: String = #file,
               function: String = #function, line: Int = #line,
               column: Int = #column) {
        
        let dic: [String: Any] = [
            "error": error
        ]
        let appendDic = self.getAppendInfo(file, function, line, column)
        
        let event = Event(level: .error)
        event.message = "\(message.rawValue) - \(-10000000) - \(NSError.protonMailErrorDomain("DataService"))"
        event.extra = extra + appendDic + dic
        event.user = self.getUsesr(currentUser: user)
        SentrySDK.capture(event: event)
    }
    
    private func getUsesr(currentUser: UserManager?=nil) -> Sentry.User {
        guard let currentUser = currentUser else {
            return Sentry.User(userId: "Not record")
        }
        let user = Sentry.User(userId: currentUser.userinfo.userId)
        return user
    }
    
    private func getAppendInfo(_ file: String, _ function: String, _ line: Int, _ column: Int) -> [String: Any] {
        var ver = "1.0.0"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        
        let appendDic: [String: Any] = [
            "file": file,
            "function": function,
            "line": line,
            "column": column,
            "uuid": UIDevice.current.identifierForVendor?.uuidString ?? "UnknowUUID",
            "DeviceModel" : UIDevice.current.model,
            "DeviceVersion" : UIDevice.current.systemVersion,
            "AppVersion" : "iOS_\(ver)",
        ]
        return appendDic
    }
}

extension Analytics {
    
    enum Events: String {
        case keychainError = "Keychain Error"
        case notificationError = "Notification Error"
        case sendMessageError = "Send Message Error"
        case saveDraftError = "Save Draft Error"
        case uploadAttachmentError = "Upload Att Error"
        case fetchMetadata = "FetchMetadata"
        case grtJSONSerialization = "GRTJSONSerialization"
        case vcard = "vcard"
        case authError = "AuthError"
        case updateAddressIDError = "UpdateAddressID Error"
        case purgeOldMessages = "Purge Old Messages"
        case queueError = "Queue Error"
        case updateLoginPassword = "Update Login Password"
        case updateMailBoxPassword = "Update MailBox Password"
        case fetchSubscriptionData = "Fetch Subscription Data"
        case coreDataError = "Core Data Error"
        case menuSetupFailed = "Menu Failed to setup"
        case usersRestoreFailed = "Users Restore Failed"
        case coredataIssue = "CoreData Issue"
        case decryptedMessageBodyFailed = "Decrypted Message Body Failed"
    }
    
    struct Reason {
        static let reason = "Reason"
        static let tokenRevoke = "Token Revoke"
        static let delinquent = "Delinquent limitation"
        static let logoutAll = "Logout All"
        static let userAction = "User Action"
        static let status = "status"
    }
}
