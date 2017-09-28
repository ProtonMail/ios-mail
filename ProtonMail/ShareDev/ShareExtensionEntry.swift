//
//  ShareExtensionEntry.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/28/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

@objc(ShareExtensionEntry)

class ShareExtensionEntry : UINavigationController {
    
    init() {
        super.init(rootViewController: ShareUnlockViewController(nibName: "ShareUnlockViewController", bundle: nil))
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.size.height)
        UIView.animate(withDuration: 0.50, animations: { () -> Void in
            self.view.transform = CGAffineTransform.identity
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
