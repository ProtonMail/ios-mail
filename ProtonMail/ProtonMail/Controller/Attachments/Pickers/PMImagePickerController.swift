//
//  PMImagePickerController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/31/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import UIKit
import Photos

#if APP_EXTENSION

class PMImagePickerController: UIImagePickerController {
    internal func setup(withDelegate delegate: UIImagePickerControllerDelegate&UINavigationControllerDelegate) {
        self.delegate = delegate
        self.sourceType = .photoLibrary
        self.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeImage as String]
    }
}

#else

import DKImagePickerController

class PMImagePickerController: DKImagePickerController {
    internal func setup(withDelegate delegate: ImageProcessor) {
        self.sourceType = .photo
        self.didSelectAssets = { assets in
            assets.compactMap{ $0.originalAsset }.forEach(delegate.process)
        }
    }
}

#endif

extension PMImagePickerController {
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
}
