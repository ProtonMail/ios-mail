//
//  SettingsViewModel.swift
//  ProtonMail - Created on 12/12/18.
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


public enum SettingAccountSection : Int, CustomStringConvertible {
    case account = 0
    case addresses = 1
    case snooze = 2
    case mailbox = 3
    
    public var description : String {
        switch(self){
        case .account:
            return LocalString._account
        case .addresses:
            return LocalString._addresses
        case .snooze:
            return LocalString._snooze
        case .mailbox:
            return LocalString._mailbox
        }
    }
}

public enum AccountItem : Int, CustomStringConvertible {
    case singlePassword = 0
    case loginPassword = 1
    case mailboxPassword = 2
    case recovery = 3
    case storage = 4
    
    public var description : String {
        switch(self){
        case .singlePassword:
            return LocalString._single_password
        case .loginPassword:
            return LocalString._login_password
        case .mailboxPassword:
            return LocalString._mailbox_password
        case .recovery:
            return LocalString._recovery_email
        case .storage:
            return LocalString._mailbox_size
        }
    }
}

public enum AddressItem : Int, CustomStringConvertible {
    case addr = 0
    case displayName = 1
    case signature = 2
    case mobileSignature = 3
    
    public var description : String {
        switch(self){
        case .addr:
            return LocalString._general_default
        case .displayName:
            return LocalString._settings_display_name_title
        case .signature:
            return LocalString._settings_signature_title
        case .mobileSignature:
            return LocalString._settings_mobile_signature_title
        }
    }
}


public enum SnoozeItem : Int, CustomStringConvertible {
    case autolock = 0
    case language = 1
    case combinContacts = 2
    case cleanCache = 3
    
    public var description : String {
        switch(self){
        case .autolock:
            return LocalString._auto_lock
        case .language:
            return LocalString._app_language
        case .combinContacts:
            return LocalString._combined_contacts
        case .cleanCache:
            return LocalString._local_cache_management
        }
    }
}

public enum MailboxItem : Int, CustomStringConvertible {
    case privacy = 0
    case search = 1
    case labelFolder = 2
    case gestures = 3
    case storage = 4
    
    public var description : String {
        switch(self){
        case .privacy:
            return LocalString._privacy
        case .search:
            return LocalString._general_search_placeholder
        case .labelFolder:
            return LocalString._label_and_folders
        case .gestures:
            return LocalString._swiping_gestures
        case .storage:
            return LocalString._local_storage_limit
        }
    }
}


protocol SettingsAccountViewModel : AnyObject {
    var sections: [SettingAccountSection] { get set }
    var accountItems: [AccountItem] { get set }
    var addrItems: [AddressItem] { get set }
    var mailboxItems: [MailboxItem] {get set}
    
    var setting_swipe_action_items : [SSwipeActionItems] { get set}
    var setting_swipe_actions : [MessageSwipeAction] { get set }
    
    var storageText : String { get }
    var recoveryEmail : String { get }
    
    var email : String { get }
    var displayName : String { get }
    
    var defaultSignatureStatus: String { get }
    var defaultMobileSignatureStatus: String { get }
    
    func updateItems()
}

class SettingsAccountViewModelImpl : SettingsAccountViewModel {
    var sections: [SettingAccountSection] = [ .account, .addresses, .mailbox]
    var accountItems: [AccountItem] = [.singlePassword, .recovery, .storage]
    var addrItems: [AddressItem] = [.addr, .displayName, .signature, .mobileSignature]
    var mailboxItems :  [MailboxItem] = [.privacy, /* .search,*/ .labelFolder, .gestures]
    
    var setting_swipe_action_items : [SSwipeActionItems] = [.left, .right]
    var setting_swipe_actions : [MessageSwipeAction]     = [.trash, .spam,
                                                            .star, .archive, .unread]
    var userManager: UserManager
    
    init(user : UserManager) {
        self.userManager = user
    }
    
    func updateItems() {
        if self.userManager.userInfo.passwordMode == 1 {
            accountItems = [.singlePassword, .recovery, .storage]
        } else {
            accountItems = [.loginPassword, .mailboxPassword, .recovery, .storage]
        }
    }
    
    var storageText: String {
        get {
            let usedSpace = self.userManager.userInfo.usedSpace
            let maxSpace = self.userManager.userInfo.maxSpace
            let formattedUsedSpace = ByteCountFormatter.string(fromByteCount: Int64(usedSpace), countStyle: ByteCountFormatter.CountStyle.binary)
            let formattedMaxSpace = ByteCountFormatter.string(fromByteCount: Int64(maxSpace), countStyle: ByteCountFormatter.CountStyle.binary)
            
            return "\(formattedUsedSpace)/\(formattedMaxSpace)"
        }
    }
    
    var recoveryEmail : String {
        get {
            return self.userManager.userInfo.notificationEmail
        }
    }
    
    
    var email : String {
        get {
            return self.userManager.defaultEmail
        }
        
    }
    var displayName : String {
        get {
            return self.userManager.defaultDisplayName
        }
    }
    var defaultSignatureStatus: String {
        get {
            if self.userManager.defaultSignatureStatus {
                return "On"
            } else {
                return "Off"
            }
        }
    }
    var defaultMobileSignatureStatus: String {
        get {
            if self.userManager.showMobileSignature {
                return "On"
            } else {
                return "Off"
            }
        }
    }
    
//    var addresses : [add]
}
