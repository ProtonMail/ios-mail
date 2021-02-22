//
//  AccessibleCell.swift
//  ProtonMail
//
//  Created by denys zelenchuk on 08.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

fileprivate let maxDeepness = 2
fileprivate var cellIdentifiers = Set<String>()

/**
 Assigns accessibility identifiers to the Cell and cell class members that belong to UIView, UIButton and UITextField types using reflection.
 */
protocol AccessibleCell {
    func generateCellAccessibilityIdentifiers(_ uniqueIdentifier: String)
}

extension AccessibleCell {
    
    /// Bla bla
    func generateCellAccessibilityIdentifiers(_ uniqueIdentifier: String) {
        #if DEBUG
        let mirror = Mirror(reflecting: self)
        assignIdentifiers(mirror, uniqueIdentifier, 0)
        #endif
    }
    
    private func assignIdentifiers(_ mirror: Mirror, _ uniqueIdentifier: String, _ deepnessLevel: Int) {
        
        if deepnessLevel > maxDeepness { return }
        
        let cell = self as? UIView
        let replacedUniqueIdentifier = uniqueIdentifier.replacingOccurrences(of: " ", with: "_")
        
        cell?.accessibilityIdentifier = "\(type(of: self)).\(replacedUniqueIdentifier)"
        cellIdentifiers.insert((cell?.accessibilityIdentifier)!)
        
        for child in mirror.children {
            if let view = child.value as? UIView {
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "")
                let viewMirror = Mirror(reflecting: view)
                
                if viewMirror.children.count > 0 {
                   assignIdentifiers(viewMirror, replacedUniqueIdentifier, deepnessLevel + 1)
                }
                
                view.accessibilityIdentifier = "\(replacedUniqueIdentifier).\(identifier!)"
                cellIdentifiers.insert((cell?.accessibilityIdentifier)!)
           } else if let view = child.value as? UIButton,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                let viewMirror = Mirror(reflecting: view)
            
                if viewMirror.children.count > 0 {
                    assignIdentifiers(viewMirror, replacedUniqueIdentifier, deepnessLevel + 1)
                }
            
                view.accessibilityIdentifier = "\(replacedUniqueIdentifier).\(identifier)"
                cellIdentifiers.insert(view.accessibilityIdentifier!)
           } else if let view = child.value as? UITextField,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {
                let viewMirror = Mirror(reflecting: view)
            
                if viewMirror.children.count > 0 {
                   assignIdentifiers(viewMirror, replacedUniqueIdentifier, deepnessLevel + 1)
                }
            
                view.accessibilityIdentifier = "\(replacedUniqueIdentifier).\(identifier)"
                cellIdentifiers.insert(view.accessibilityIdentifier!)
           }
        }
    }
}
