//
//  LoadingView.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class LoadingView: UIView {
    
    private let animationDuration: NSTimeInterval = 1
    private var isShowing = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    private weak var tableView: UITableView?
    
    class func viewForOwner(owner: AnyObject?) -> LoadingView {
        let objects = NSBundle.mainBundle().loadNibNamed("LoadingView", owner: owner, options: nil)
        for object in objects {
            if let view = object as? LoadingView {
                return view
            }
        }
        
        assertionFailure("LoadingView did not load from nib!")
        return LoadingView()
    }
    
    func hide() {
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.alpha = 0
            }) { (finished) -> Void in
                UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in
                    self.tableView?.tableFooterView = nil
                    self.isShowing = false
                })
        }
    }
    
    func showForTableView(tableView: UITableView) {
        if isShowing {
            return
        }
        
        isShowing = true
        
        self.tableView = tableView
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.tableView?.tableFooterView = self
            return
            }) { (finished) -> Void in
                UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in
                    self.alpha = 1.0
                    })
        }
    }
    

}