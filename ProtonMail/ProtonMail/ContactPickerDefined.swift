//
//  ContactPickerDefined.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

//    #define UIColorFromRGB(rgbValue) [UIColor \
//    colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
//    green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
//    blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
//



class ContactPickerDefined {
    static let kMaxVisibleRows : CGFloat                = 100;
    static let kAnimationSpeed : CGFloat                = 0.25;
    static let ROW_HEIGHT : CGFloat                     = 64.0;
    static let ContactsTableViewCellName : String       = "ContactsTableViewCell"
    static let ContactsTableViewCellIdentifier : String = "ContactCell"
    static let kPrompt : String                         = "To";
}
