//
//  CameraAttachmentProvider.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 28/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

final class CameraAttachmentProvider: AnyImagePickerDelegate {
    override var alertAction: UIAlertAction {
        return UIAlertAction(title: LocalString._take_a_photo, style: .default) { action in
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = UIImagePickerController.SourceType.camera
                self.controller.present(picker, animated: true, completion: nil)
            }
        }
    }
}

