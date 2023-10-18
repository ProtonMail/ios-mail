//
//  PhotoAttachmentProvider.swift
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
import PhotosUI
import ProtonCoreUIFoundations

class PhotoAttachmentProvider: AnyImagePickerDelegate {
    override var actionSheetItem: PMActionSheetItem {
        return PMActionSheetItem(
            title: LocalString._from_your_photo_library,
            icon: IconProvider.image,
            iconColor: ColorProvider.IconNorm
        ) { _ in
            var config = PHPickerConfiguration()
            config.selectionLimit = 0
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.controller?.present(picker, animated: true, completion: nil)
        }
    }
}

extension PhotoAttachmentProvider: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        results.forEach { process(result: $0) }
    }
}
