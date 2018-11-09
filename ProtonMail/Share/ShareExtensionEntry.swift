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
    
    var appCoordinator : ShareAppCoordinator?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup()
    }
    
    private func setup() {
        appCoordinator = ShareAppCoordinator(navigation: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appCoordinator?.start()
    }
}
