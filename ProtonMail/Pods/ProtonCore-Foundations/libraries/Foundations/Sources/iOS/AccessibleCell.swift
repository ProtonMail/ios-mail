//
//  AccessibleCell.swift
//  ProtonCore-Foundations - Created on 08.09.20.
//
//  Copyright (c) 2022 Proton Technologies AG
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

private let maxDeepness = 2
private var cellIdentifiers = Set<String>()

/**
 Assigns accessibility identifiers to the Cell and cell class members that belong to UIView, UIButton and UITextField types using reflection.
 */
public protocol AccessibleCell {
    func generateCellAccessibilityIdentifiers(_ uniqueIdentifier: String)
}

public extension AccessibleCell {
    
    func generateCellAccessibilityIdentifiers(_ uniqueIdentifier: String) {
        #if DEBUG
        let mirror = Mirror(reflecting: self)
        assignIdentifiers(mirror, uniqueIdentifier, 0)
        #endif
    }
    
    #if DEBUG
    private func assignIdentifiers(_ mirror: Mirror, _ originalUniqueIdentifier: String, _ deepnessLevel: Int) {
        
        if deepnessLevel > maxDeepness { return }
        
        let cell = self as? UIView
        let uniqueIdentifier = originalUniqueIdentifier.replacingOccurrences(of: " ", with: "_")
        
        cell?.accessibilityIdentifier = "\(type(of: self)).\(uniqueIdentifier)"
        cellIdentifiers.insert((cell?.accessibilityIdentifier)!)
        
        for child in mirror.children {
            if let view = child.value as? UIView {
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "")
                let viewMirror = Mirror(reflecting: view)
                
                if viewMirror.children.count > 0 {
                   assignIdentifiers(viewMirror, uniqueIdentifier, deepnessLevel + 1)
                }
                
                view.accessibilityIdentifier = "\(uniqueIdentifier).\(identifier!)"
                cellIdentifiers.insert((cell?.accessibilityIdentifier)!)
           } else if let view = child.value as? UIButton,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                let viewMirror = Mirror(reflecting: view)
            
                if viewMirror.children.count > 0 {
                    assignIdentifiers(viewMirror, uniqueIdentifier, deepnessLevel + 1)
                }
            
                view.accessibilityIdentifier = "\(uniqueIdentifier).\(identifier)"
                cellIdentifiers.insert(view.accessibilityIdentifier!)
           } else if let view = child.value as? UITextField,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                let viewMirror = Mirror(reflecting: view)
            
                if viewMirror.children.count > 0 {
                   assignIdentifiers(viewMirror, uniqueIdentifier, deepnessLevel + 1)
                }
            
                view.accessibilityIdentifier = "\(uniqueIdentifier).\(identifier)"
                cellIdentifiers.insert(view.accessibilityIdentifier!)
           }
        }
    }
    #endif
}
