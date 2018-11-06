//
//  ContactPickerDefined.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


class ContactPickerDefined {
    static let kMaxVisibleRows : CGFloat                = 100;
    static let kAnimationSpeed : CGFloat                = 0.25
    static let ROW_HEIGHT : Int                         = 64
    static let kCellHeight : Int                        = 44
    
    static let ContactsTableViewCellName                = "ContactsTableViewCell"
    static let ContactsTableViewCellIdentifier          = "ContactCell"
    static let ContactGroupTableViewCellName            = "ContactGroupsViewCell"
    static let ContactGroupTableViewCellIdentifier      = "ContactGroupCustomCell"
    
    //localized prompt string //_prompt = NSLocalizedStringWithDefaultValue(@"MBContactPickerPrompt", nil, [NSBundle mainBundle], kPrompt, @"Default Prompt text shown in the prompt cell")
    static let kPrompt : String                         = "To"
    
    static let kDefaultEntryText : String               = " "
}
