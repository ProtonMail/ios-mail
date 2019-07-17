//
//  EmbeddingViewCoordinator.swift
//  ProtonMail - Created on 11/04/2019.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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
    

import Foundation
// this is the UI

//can we move this to  view controller -- notes from feng.
class TableContainerViewCoordinator: NSObject, CoordinatorNew {
    func start() {
        // ?
    }
    
    
    internal func embedChild(indexPath: IndexPath, onto cell: UITableViewCell) {
        fatalError()
    }
    
    internal func embed(_ child: UIViewController,
                        onto view: UIView,
                        layoutGuide: UILayoutGuide? = nil,
                        ownedBy controller: UIViewController) {
        assert(controller.isViewLoaded, "Attempt to embed child VC before parent's view was loaded - will cause glitches")
        
        // remove child from old parent
        if let parent = child.parent, parent != controller {
            child.willMove(toParent: nil)
            if child.isViewLoaded {
                child.view.removeFromSuperview()
            }
            child.removeFromParent()
        }
        
        // add child to new parent
        controller.addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        child.didMove(toParent: controller)
        
        // autolayout guides priority: parameter, safeArea, no guide
        if let specialLayoutGuide = layoutGuide {
            specialLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
            specialLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
            specialLayoutGuide.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
            specialLayoutGuide.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
        } else if #available(iOS 11.0, *) {
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
        } else {
            view.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
        }
    }
}
