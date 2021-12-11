//
//  PMImagePickerController.swift
//  ProtonMail - Created on 3/31/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import Photos

#if APP_EXTENSION

class PMImagePickerController: UIImagePickerController, AccessibleView {
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
