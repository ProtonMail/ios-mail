//
//  ContactPickerDefined.swift
//  Proton Mail - Created on 4/27/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

class ContactPickerDefined {
    static let kMaxVisibleRows: CGFloat                = 100
    static let ROW_HEIGHT: Int                         = 64
    static let kCellHeight: Int                        = 44

    static let ContactsTableViewCellName                = "ContactsTableViewCell"
    static let ContactsTableViewCellIdentifier          = "ContactCell"

    // localized prompt string //_prompt = NSLocalizedStringWithDefaultValue(@"MBContactPickerPrompt", nil, [NSBundle mainBundle], kPrompt, @"Default Prompt text shown in the prompt cell")
    static let kPrompt: String                         = "To"

    static let kDefaultEntryText: String               = " "
}
