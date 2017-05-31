//
//  UITableViewExtension.swift
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

extension UITableView {
    
    fileprivate struct Constant {
        static let animationDuration: TimeInterval = 1
    }
    
    func hideLoadingFooter(replaceWithView view: UIView? = UIView(frame: CGRect.zero)) {
        UIView.animate(withDuration: Constant.animationDuration, animations: { () -> Void in
            self.tableFooterView?.alpha = 0
            return
            }, completion: { (finished) -> Void in
                UIView.animate(withDuration: Constant.animationDuration, animations: { () -> Void in
                    self.tableFooterView = view
                })
        }) 
    }
    func noSeparatorsBelowFooter() {
        tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func showLoadingFooter() {
        tableFooterView = LoadingView.viewForOwner(self)
        tableFooterView?.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
    }    
}



extension UITableView {
    
    func RegisterCell(_ cellID : String) {
        self.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
    }
}
