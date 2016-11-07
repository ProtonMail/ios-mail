//
//  Snapshot.swift
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
import UIKit

class Snapshot {
    
    private struct Tag {
        static let snapshot = 101
    }
    
    // the launchScreen
    private struct NibName {
        static let Name = "LaunchScreen"
    }
    
    // create a view and overlay the screen
    func didEnterBackground(application: UIApplication) {
        if let window = application.keyWindow {
            if let launchScreen = NSBundle.mainBundle().loadNibNamed(NibName.Name, owner: window, options: nil) {
                let snapshotView = launchScreen.first as? UIView ?? {
                    let view = UIView(frame: window.bounds)
                    view.backgroundColor = UIColor.ProtonMail.Blue_85B1DE
                    return view
                    }() as UIView
                
                snapshotView.tag = Tag.snapshot
                window.addSubview(snapshotView)
                snapshotView.mas_makeConstraints { (make) -> Void in
                    make.top.equalTo()(window)
                    make.left.equalTo()(window)
                    make.right.equalTo()(window)
                    make.bottom.equalTo()(window)
                }
            }
        }
    }
    
    func willEnterForeground(application: UIApplication) {
        if let snapshotView = application.keyWindow?.viewWithTag(Tag.snapshot) {
            snapshotView.removeFromSuperview()
        }
    }
}
