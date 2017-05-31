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
    
    fileprivate struct Tag {
        static let snapshot = 101
    }
    
    // the launchScreen
    fileprivate struct NibName {
        static let Name = "LaunchScreen"
    }
    
    static var cachedSnapshotView : UIView? = nil
    
    // create a view and overlay the screen
    func didEnterBackground(_ application: UIApplication) {
        if let window = application.keyWindow {
            guard let view = Snapshot.cachedSnapshotView else {
                if let launchScreen = Bundle.main.loadNibNamed(NibName.Name, owner: window, options: nil),
                    let snapshotView = launchScreen.first as? UIView {
                    snapshotView.tag = Tag.snapshot
                    Snapshot.cachedSnapshotView = snapshotView
                    showView(window, view: snapshotView)
                } else {
                    let v = getDefaultView()
                    Snapshot.cachedSnapshotView = v
                    showView(window, view: v)
                }
                return
            }
            showView(window, view: view)
        }
    }
    
    func showView(_ window: UIWindow, view: UIView) {
        window.addSubview(view)
        view.mas_makeConstraints { (make) -> Void in
            make?.top.equalTo()(window)
            make?.left.equalTo()(window)
            make?.right.equalTo()(window)
            make?.bottom.equalTo()(window)
        }
    }
    
    func getDefaultView() -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ProtonMail.Blue_85B1DE
        view.tag = Tag.snapshot
        return view
    }
    
    func willEnterForeground(_ application: UIApplication) {
        if let snapshotView = application.keyWindow?.viewWithTag(Tag.snapshot) {
            snapshotView.removeFromSuperview()
        }
    }
}
