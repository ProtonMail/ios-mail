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
import Photos
import ProtonCore_UIFoundations

// abstract
class AnyImagePickerDelegate: NSObject, AttachmentProvider, ImageProcessor {
    weak var controller: AttachmentController?

    init(for controller: AttachmentController) {
        self.controller = controller
    }

    var actionSheetItem: PMActionSheetItem {
        fatalError() // override
    }

    func checkPhotoPermission(_ handler: @escaping (_ granted: Bool) -> Void) {
        func hasPhotoPermission() -> Bool {
            return PHPhotoLibrary.authorizationStatus() == .authorized
        }

        func needsToRequestPhotoPermission() -> Bool {
            return PHPhotoLibrary.authorizationStatus() == .notDetermined
        }

        if hasPhotoPermission() {
            handler(true)
        } else if needsToRequestPhotoPermission() {
            PHPhotoLibrary.requestAuthorization({ status in
                DispatchQueue.main.async(execute: { () in
                    hasPhotoPermission() ? handler(true) : handler(false)
                })
            })
        } else {
            handler(false)
        }
    }
}

extension AnyImagePickerDelegate: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let asset = info[UIImagePickerController.InfoKey.phAsset.rawValue] as? PHAsset {
            self.process(asset: asset)
            picker.dismiss(animated: true, completion: nil)
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage {
            self.process(original: originalImage).done { (_) in
                picker.dismiss(animated: true, completion: nil)
            }.cauterize()
        } else if let referenceUrl = info[UIImagePickerController.InfoKey.referenceURL.rawValue] as? URL {
            // If the info dict does not contain the PHAsset, that means we do not have access to read the file.
            let result = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl], options: nil)
            if let asset = result.firstObject {
                self.process(asset: asset)
            } else {
                self.controller?.error(title: LocalString._no_photo_library_permission_title,
                                       description: LocalString._no_photo_library_permission_content)
            }
            picker.dismiss(animated: true, completion: nil)
        } else {
            self.controller?.error(LocalString._cant_copy_the_file)
            picker.dismiss(animated: true, completion: nil)
        }
    }

    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
