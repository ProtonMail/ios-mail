//
//  File.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 28/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Photos

// abstract
class AnyImagePickerDelegate: NSObject, AttachmentProvider, ImageProcessor {
    weak var controller: AttachmentController!
    
    init(for controller: AttachmentController) {
        self.controller = controller
    }
    
    var alertAction: UIAlertAction {
        fatalError() // override
    }
}

extension AnyImagePickerDelegate: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let url = info[UIImagePickerControllerReferenceURL] as? NSURL,
            let asset = PHAsset.fetchAssets(withALAssetURLs: [url as URL], options: nil).firstObject
        {
            self.process(asset: asset)
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.process(original: originalImage)
        } else {
            self.controller.error(LocalString._cant_copy_the_file)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
