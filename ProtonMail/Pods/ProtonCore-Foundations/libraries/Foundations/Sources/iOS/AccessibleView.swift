//
//  Accessible.swift
//  ProtonCore-Foundations - Created on 03.09.20.
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit

private let maxDeepness = 1
private var viewIdentifiers = Set<String>()

/**
 Assigns accessibility identifiers to the ViewController class members that belong to UIView, UIButton, UIBarItem and UITextField class types using reflection.
*/
public protocol AccessibleView {
    func generateAccessibilityIdentifiers()
    func generateAccessibilityIdentifiers(rootType: Any.Type?)
    func assignIdentifier(_ object: UIAccessibilityIdentification, prefix: String?, identifier: String)
}

public extension AccessibleView {

    /**
     Traverse through the current object's mirror and to its super mirror til the rootType is reached, meanwhile assign the accessibilityIdentifiers to mirror.children.
     
     - Parameter rootType: The final type that one wants to assign identifiers. Default is *Self*
     
    # Notes
     * **Lazy var** could be nil as mirror.children, so one must make sure it's init before the call.
     */
    func generateAccessibilityIdentifiers(rootType: Any.Type?) {
        #if DEBUG
        let mirror = Mirror(reflecting: self)
        assignIdentifiers(mirror: mirror, rootType: rootType)
        #endif
    }

    func generateAccessibilityIdentifiers() {
        generateAccessibilityIdentifiers(rootType: Self.self)
    }
    
    /**
     Assign identifier to the object with the given prefix & identifier.
     It will be *SelfType.(prefix.)identifier*
     
     - Parameter object: The object that one wants to assign the identifier
     - Parameter prefix: The prefix will be in front of identifier
     - Parameter identifier: The identifier for this object
     
     */
    func assignIdentifier(_ object: UIAccessibilityIdentification, prefix: String? = nil, identifier: String) {
        #if DEBUG
        var prefixIdentifier = identifier
        if let prefix = prefix {
            prefixIdentifier = "\(prefix).\(identifier)"
        }
        object.accessibilityIdentifier = "\(type(of: self)).\(prefixIdentifier)"
        #endif
    }
    
    #if DEBUG
    /**
        The inner one of the public assignIdentifiers in order to have recursive call on the super mirror.
     */
    private func assignIdentifiers(mirror: Mirror, rootType: Any.Type? ) {
        assignIdentifiers(mirror: mirror, deepnessLevel: 0)
        
        if mirror.subjectType != rootType,
           let superMirror = mirror.superclassMirror {
            assignIdentifiers(mirror: superMirror, rootType: rootType)
        }
    }
    
    /**
     Assign the identifiers to each child under the mirror once they're the following types.
      Recursively call this func once there're children under that child.
     
     - Parameter mirror: Whose children will be looped over.
     - Parameter prefix: The prefix will be used in assigning identifiers. See `assignIdentifier(_ object..`. This will be passed down with the child's identifier.
     - Parameter deepnessLevel: The current level the func is in. This should not be greater than `maxDeepness` to avoid going too deep.
     
     # The types that will be considered
      * UIView
      * UIBarItem
     # Notice
      * **Lazy var** should be init beforehand, o.w. the value will be nil
     */
    private func assignIdentifiers(mirror: Mirror, prefix: String? = nil, deepnessLevel: Int) {
        
        if deepnessLevel > maxDeepness { return }

        for child in mirror.children {
            var object: UIAccessibilityIdentification?
            
            switch child.value {
            case let view as UIView:
                object = view
            case let barItem as UIBarItem:
                object = barItem
            default:
                break
            }
            
            if let object = object, let identifier = cleanLabel(child.label) {
                let viewMirror = Mirror(reflecting: object)
                
                if viewMirror.children.count > 0 {
                    var prefixIdentifier = identifier
                    if let prefix = prefix {
                        prefixIdentifier = "\(prefix).\(identifier)"
                    }
                    assignIdentifiers(mirror: viewMirror, prefix: prefixIdentifier, deepnessLevel: deepnessLevel + 1)
                }
                assignIdentifier(object, prefix: prefix, identifier: identifier)
                viewIdentifiers.insert(object.accessibilityIdentifier!)
            }
        }
    }
    
    /// Clean the label, esp. for lazy var.
    private func cleanLabel(_ label: String?) -> String? {
        label?.replacingOccurrences(of: ".storage", with: "")
            .replacingOccurrences(of: "$__lazy_storage_$_", with: "")
    }
    #endif
}

public extension UINavigationItem {
    
    func assignNavItemIndentifiers() {
        let leftIdentifier = "\(type(of: self)).leftBarButtonItem"
        self.leftBarButtonItem?.accessibilityIdentifier = leftIdentifier

        let rightIdentifier = "\(type(of: self)).rightBarButtonItem"
        self.rightBarButtonItem?.accessibilityIdentifier = rightIdentifier
    }
}
