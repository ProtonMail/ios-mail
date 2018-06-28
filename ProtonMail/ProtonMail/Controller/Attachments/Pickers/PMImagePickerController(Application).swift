//
//  PMImagePickerController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/31/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import UIKit
import Photos
import DKImagePickerController

class PMImagePickerController : DKImagePickerController {
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    internal func setup(withDelegate delegate: ImageProcessor) {
        self.sourceType = .photo
        self.didSelectAssets = { assets in
            assets.compactMap{ $0.originalAsset }.forEach(delegate.process)
        }
    }
}

