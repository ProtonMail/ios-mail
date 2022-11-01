//
//  EmbeddingViewCoordinator.swift
//  Proton Mail - Created on 11/04/2019.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

// can we move this to  view controller -- notes from feng.
class TableContainerViewCoordinator: NSObject {
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
        if view.subviews.isEmpty {
            view.addSubview(child.view)
        } else if let existedView = view.subviews.first {
            if existedView != child.view {
                existedView.removeFromSuperview()
                view.addSubview(child.view)
            }
        }

        child.didMove(toParent: controller)

        // autolayout guides priority: parameter, safeArea, no guide
        if let specialLayoutGuide = layoutGuide {
            specialLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
            specialLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
            specialLayoutGuide.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
            specialLayoutGuide.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
        } else {
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
        }
    }
}
