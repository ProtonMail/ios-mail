//
//  AccessibleCell.swift
//  ProtonMail
//
//  Created by denys zelenchuk on 08.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

protocol AccessibleCell {
    func generateCellAccessibilityIdentifiers(_ uniqueIdentifier: String)
}

extension AccessibleCell {
    
    func generateCellAccessibilityIdentifiers(_ uniqueIdentifier: String) {
        #if DEBUG
        let mirror = Mirror(reflecting: self)
        let cell = self as? UIView
        
        let replacedUniqueIdentifier = uniqueIdentifier.replacingOccurrences(of: " ", with: "_")
        
        cell?.accessibilityIdentifier = "\(type(of: self)).\(replacedUniqueIdentifier)"

        for child in mirror.children {
            if let view = child.value as? UIView,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                view.accessibilityIdentifier = "\(replacedUniqueIdentifier).\(identifier)"
            }
        }
        #endif
    }
}

