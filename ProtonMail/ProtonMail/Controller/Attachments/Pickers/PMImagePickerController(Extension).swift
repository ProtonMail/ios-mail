//
//  PMImagePickerController(Extension).swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 28/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import Photos

class PMImagePickerController : UIImagePickerController {
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    internal func setup(withDelegate delegate: UIImagePickerControllerDelegate&UINavigationControllerDelegate) {
        self.delegate = delegate
        self.sourceType = .photoLibrary
        self.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeImage as String]
    }
}
