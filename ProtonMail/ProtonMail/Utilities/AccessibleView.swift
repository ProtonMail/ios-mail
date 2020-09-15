//
//  Accessible.swift
//  ProtonMail
//
//  Created by denys zelenchuk on 03.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

fileprivate let maxDeepness = 1
fileprivate var viewIdentifiers = Set<String>()

/**
 Assigns accessibility identifiers to the ViewController class members that belong to UIView, UIButton, UIBarItem and UITextField class types using reflection.
*/
protocol AccessibleView {
    func generateAccessibilityIdentifiers()
}

extension AccessibleView {

    func generateAccessibilityIdentifiers() {
        #if DEBUG
        let mirror = Mirror(reflecting: self)
        assignIdentifiers(mirror, 0)
        #endif
    }
    
    private func assignIdentifiers(_ mirror: Mirror, _ deepnessLevel: Int) {
        
        if deepnessLevel > maxDeepness { return }

        for child in mirror.children {
            if let view = child.value as? UIView {
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "")
                let viewMirror = Mirror(reflecting: view)
                
                if viewMirror.children.count > 0 {
                    assignIdentifiers(viewMirror, deepnessLevel + 1)
                }
                
                view.accessibilityIdentifier = "\(type(of: self)).\(identifier!)"
                viewIdentifiers.insert(view.accessibilityIdentifier!)
            } else if let view = child.value as? UIButton,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                let viewMirror = Mirror(reflecting: view)
                
                if viewMirror.children.count > 0 {
                    assignIdentifiers(viewMirror, deepnessLevel + 1)
                }
                
                view.accessibilityIdentifier = "\(type(of: self)).\(identifier)"
                viewIdentifiers.insert(view.accessibilityIdentifier!)
            } else if let view = child.value as? UITextField,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                let viewMirror = Mirror(reflecting: view)
                
                if viewMirror.children.count > 0 {
                    assignIdentifiers(viewMirror, deepnessLevel + 1)
                }
                
                view.accessibilityIdentifier = "\(type(of: self)).\(identifier)"
                viewIdentifiers.insert(view.accessibilityIdentifier!)
            } else if let view = child.value as? UIBarItem,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                view.accessibilityIdentifier = "\(type(of: self)).\(identifier)"
                viewIdentifiers.insert(view.accessibilityIdentifier!)
            } else if let view = child.value as? UIBarButtonItem,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                let viewMirror = Mirror(reflecting: view)

                if viewMirror.children.count > 0 {
                   assignIdentifiers(viewMirror, deepnessLevel + 1)
                }

                view.accessibilityIdentifier = "\(type(of: self)).\(identifier)"
                viewIdentifiers.insert(view.accessibilityIdentifier!)
            }
        }
    }
}


extension UINavigationItem {
    
    func assignNavItemIndentifiers() {
        self.leftBarButtonItem?.accessibilityIdentifier = "\(type(of: self)).leftBarButtonItem"
        self.rightBarButtonItem?.accessibilityIdentifier = "\(type(of: self)).rightBarButtonItem"
    }
}
