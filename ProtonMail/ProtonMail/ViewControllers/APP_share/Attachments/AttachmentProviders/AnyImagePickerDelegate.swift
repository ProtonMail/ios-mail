//
//  AnyImagePickerDelegate.swift
//  Proton Mail - Created on 28/06/2018.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreUIFoundations
import UIKit

// abstract
class AnyImagePickerDelegate: NSObject, AttachmentProvider, ImageProcessor {
    weak var controller: AttachmentController?

    init(for controller: AttachmentController) {
        self.controller = controller
    }

    var actionSheetItem: PMActionSheetItem {
        fatalError() // override
    }
}

extension AnyImagePickerDelegate: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let originalImage = info[.originalImage] as? UIImage {
            self.process(original: originalImage).done { (_) in
                picker.dismiss(animated: true, completion: nil)
            }.cauterize()
        } else {
            self.controller?.error(LocalString._cant_copy_the_file)
            picker.dismiss(animated: true, completion: nil)
        }
    }

    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
