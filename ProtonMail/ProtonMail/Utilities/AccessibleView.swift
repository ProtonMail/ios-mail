//
//  Accessible.swift
//  ProtonMail
//
//  Created by denys zelenchuk on 03.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

protocol AccessibleView {
    func generateAccessibilityIdentifiers()
}

extension AccessibleView {

    func generateAccessibilityIdentifiers() {
        #if DEBUG
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            if let view = child.value as? UIView {
                
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "")
                let viewMirror = Mirror(reflecting: view)
                for viewChild in viewMirror.children {
                    if let viewChildView = viewChild.value as? UIView {
                        let viewIdentifier = viewChild.label?.replacingOccurrences(of: ".storage", with: "")
                        viewChildView.accessibilityIdentifier = "\(type(of: viewChildView)).\(viewIdentifier!)"
                    }
                }
                view.accessibilityIdentifier = "\(type(of: self)).\(identifier!)"
            }
            else if let view = child.value as? UIBarItem,
                let identifier = child.label?.replacingOccurrences(of: ".storage", with: "") {

                let viewMirror = Mirror(reflecting: view)
                for viewChild in viewMirror.children {
                    if let viewChildView = viewChild.value as? UIBarItem {
                        let viewIdentifier = viewChild.label?.replacingOccurrences(of: ".storage", with: "")
                        viewChildView.accessibilityIdentifier = "\(type(of: viewChildView)).\(viewIdentifier!)"
                    }
                }
                view.accessibilityIdentifier = "\(type(of: self)).\(identifier)"
            } else if let view = child.value as? UINavigationItem {

                let viewMirror = Mirror(reflecting: view)
                for viewChild in viewMirror.children {
                    if let viewChildView = viewChild.value as? UIBarItem {
                        let viewIdentifier = viewChild.label?.replacingOccurrences(of: ".storage", with: "")
                        viewChildView.accessibilityIdentifier = "\(type(of: viewChildView)).\(viewIdentifier!)"
                    }
                }
            }
        }
        #endif
    }
}
