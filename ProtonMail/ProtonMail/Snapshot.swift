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

import UIKit
import Foundation

class Snapshot {
    
    fileprivate struct Tag {
        static let snapshot = 101
    }
    
    // the launchScreen
    fileprivate struct NibName {
        static let Name = "LaunchScreen"
    }
    
    static var cachedSnapshotView : UIView? = nil
    
    func didEnterBackground(_ application: UIApplication) {
        guard let window = application.keyWindow else {
            return
        }
        self.show(at: window)
    }
    
    func show(at window: UIWindow) {
        let view = Snapshot.cachedSnapshotView ?? self.getFancyView(for: window) ?? self.getDefaultView()
        
        window.addSubview(view)
        view.mas_makeConstraints { (make) -> Void in
            make?.top.equalTo()(window)
            make?.left.equalTo()(window)
            make?.right.equalTo()(window)
            make?.bottom.equalTo()(window)
        }
    }
    
    func getFancyView(for window: UIWindow) -> UIView? {
        guard let view = Bundle.main.loadNibNamed(NibName.Name, owner: window, options: nil)?.first as? UIView else {
            return nil
        }
        view.tag = Tag.snapshot
        Snapshot.cachedSnapshotView = view
        return view
    }
    
    func getDefaultView() -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ProtonMail.Blue_85B1DE
        view.tag = Tag.snapshot
        Snapshot.cachedSnapshotView = view
        return view
    }
    
    func willEnterForeground(_ application: UIApplication) {
        if let snapshotView = application.keyWindow?.viewWithTag(Tag.snapshot) {
            snapshotView.removeFromSuperview()
        }
    }
}
