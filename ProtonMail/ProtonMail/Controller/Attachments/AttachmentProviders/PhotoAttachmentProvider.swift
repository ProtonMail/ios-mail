//
//  PhotoAttachmentProvider.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 28/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class PhotoAttachmentProvider: AnyImagePickerDelegate {
    override var alertAction: UIAlertAction {
        return UIAlertAction(title: LocalString._photo_library, style: .default) { action in
            let picker = PMImagePickerController()
            picker.setup(withDelegate: self)
            self.controller.present(picker, animated: true, completion: nil)
        }
    }
}
