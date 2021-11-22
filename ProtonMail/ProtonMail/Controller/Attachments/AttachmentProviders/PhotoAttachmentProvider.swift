//
//  PhotoAttachmentProvider.swift
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
import ProtonCore_UIFoundations

class PhotoAttachmentProvider: AnyImagePickerDelegate {
    override var actionSheetItem: PMActionSheetItem {
        return PMActionSheetPlainItem(title: LocalString._from_your_photo_library,
                                      icon: UIImage(named: "ic-photo"),
                                      iconColor: ColorProvider.IconNorm) { (_) -> (Void) in
            let picker = PMImagePickerController()
            picker.setup(withDelegate: self)

            #if APP_EXTENSION
            self.checkPhotoPermission { _ in
                self.controller?.present(picker, animated: true, completion: nil)
            }
            #else
            self.controller?.present(picker, animated: true, completion: nil)
            #endif
        }
    }
}
