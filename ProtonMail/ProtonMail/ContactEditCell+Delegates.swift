//
//  ContactEdit-Delegates.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/26/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



protocol ContactEditCellDelegate {
    func pick(typeInterface: ContactEditTypeInterface, sender: UITableViewCell)
    func beginEditing(textField: UITextField)
}
