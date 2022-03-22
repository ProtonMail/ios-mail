//
//  CameraAttachmentProvider.swift
//  ProtonMail - Created on 28/06/2018.
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
import ProtonCore_UIFoundations

final class CameraAttachmentProvider: AnyImagePickerDelegate {
    override var actionSheetItem: PMActionSheetItem {
        return PMActionSheetPlainItem(title: LocalString._take_new_photo,
                                      icon: IconProvider.camera,
                                      iconColor: ColorProvider.IconNorm) { (_) -> Void in
            guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) else { return }
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerController.SourceType.camera
            self.controller?.present(picker, animated: true, completion: nil)
        }
    }
}
