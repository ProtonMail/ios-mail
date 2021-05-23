//
//  Accessible.swift
//  ProtonMail - Created on 03.09.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

#if canImport(UIKit)
import Foundation
import UIKit

private let maxDeepness = 1
private var viewIdentifiers = Set<String>()

/**
 Assigns accessibility identifiers to the ViewController class members that belong to UIView, UIButton, UIBarItem and UITextField class types using reflection.
*/
public protocol AccessibleView {
    func generateAccessibilityIdentifiers()
}

public extension AccessibleView {

    func generateAccessibilityIdentifiers() {
        #if DEBUG
        let mirror = Mirror(reflecting: self)
        assignIdentifiers(mirror: mirror, deepnessLevel: 0)
        #endif
    }
    
    #if DEBUG
    private func assignIdentifiers(mirror: Mirror, prefix: String? = nil, deepnessLevel: Int) {
        
        if deepnessLevel > maxDeepness { return }

        for child in mirror.children {
            if let view = child.value as? UIView, let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                let viewMirror = Mirror(reflecting: view)
                
                if viewMirror.children.count > 0 {
                    var prefixIdentifier = identifier
                    if let prefix = prefix {
                        prefixIdentifier = "\(prefix).\(identifier)"
                    }
                    assignIdentifiers(mirror: viewMirror, prefix: prefixIdentifier, deepnessLevel: deepnessLevel + 1)
                }
                var prefixIdentifier = identifier
                if let prefix = prefix {
                    prefixIdentifier = "\(prefix).\(identifier)"
                }
                view.accessibilityIdentifier = "\(type(of: self)).\(prefixIdentifier)"
                viewIdentifiers.insert(view.accessibilityIdentifier!)
            }
        }
    }
    #endif
}

public extension UINavigationItem {
    
    func assignNavItemIndentifiers() {
        self.leftBarButtonItem?.accessibilityIdentifier = "\(type(of: self)).leftBarButtonItem"
        self.rightBarButtonItem?.accessibilityIdentifier = "\(type(of: self)).rightBarButtonItem"
    }
}
#endif
