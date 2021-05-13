//
//  CameraAttachmentProvider.swift
//  ProtonMail - Created on 28/06/2018.
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


import Foundation
import PMUIFoundations

final class CameraAttachmentProvider: AnyImagePickerDelegate {
    override var actionSheetItem: PMActionSheetItem {
        return PMActionSheetPlainItem(title: LocalString._take_new_photo, icon: UIImage(named: "ic-camera")) { (_) -> (Void) in
            guard (UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) else { return }
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerController.SourceType.camera
            self.controller?.present(picker, animated: true, completion: nil)
        }
    }
}

