//
//  EmbeddingViewCoordinator.swift
//  ProtonMail - Created on 11/04/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

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
