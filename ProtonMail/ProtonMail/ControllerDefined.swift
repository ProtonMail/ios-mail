//
//  ControllerConstants.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

//MARK : Compose view controller
public struct EncryptionStep {
    static public let DefinePassword = "DefinePassword"
    static public let ConfirmPassword = "ConfirmPassword"
    static public let DefineHintPassword = "DefineHintPassword"
}

public enum ComposeMessageAction: Int, CustomStringConvertible {
    case reply = 0
    case replyAll = 1
    case forward = 2
    case newDraft = 3
    case openDraft = 4
    case newDraftFromShare = 5
    
    /// localized description
    public var description : String {
        get {
            switch(self) {
            case .reply:
                return  LocalString._general_reply_button
            case .replyAll:
                return LocalString._general_replyall_button
            case .forward:
                return LocalString._general_forward_button
            case .newDraft, .newDraftFromShare:
                return NSLocalizedString("Draft", comment: "Action")
            case .openDraft:
                return NSLocalizedString("OpenDraft", comment: "Action")
            }
        }
    }
}
