//
//  UITableViewHeaderFooterCustomized.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 14/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

protocol SectionHeaderCustomizing { }
extension SectionHeaderCustomizing {
    func customize(header view: UIView) {
        guard let header = view as? UITableViewHeaderFooterView else {
            return
        }
        header.textLabel?.text = header.textLabel?.text?.localized
        header.textLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        header.textLabel?.textColor = .lightGray
    }
}
