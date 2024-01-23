//
//  ImageProcessor.swift
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
import PromiseKit

protocol ImageProcessor {
    func process(original originalImage: UIImage) -> Promise<Void>
}
extension ImageProcessor where Self: AttachmentProvider {

    private func writeItemToTempDirectory(_ item: Data, filename: String) throws -> URL {
        let tempFileUrl = try FileManager.default.createTempURL(forCopyOfFileNamed: filename)
        try item.write(to: tempFileUrl)
        return tempFileUrl
    }

    internal func process(original originalImage: UIImage) -> Promise<Void> {
        let fileName = "\(NSUUID().uuidString).jpg"
        let ext = "image/jpeg"
        var fileData: FileData!

#if APP_EXTENSION
        guard let data = originalImage.jpegData(compressionQuality: 0.8),
              let newUrl = try? self.writeItemToTempDirectory(data, filename: fileName) else {
            self.controller?.error(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil).description)
            return Promise()
        }
        fileData = ConcreteFileData(name: fileName, mimeType: ext, contents: newUrl)
#else
        fileData = ConcreteFileData(name: fileName, mimeType: ext, contents: originalImage)
#endif

        return self.controller?.fileSuccessfullyImported(as: fileData) ?? Promise()
    }

    func process(result: PHPickerResult) {
        let provider = result.itemProvider
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                guard error == nil, let url = url else {
                    self.controller?.error(error.debugDescription)
                    return
                }
                addAttachment(from: url)
            }
        } else if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                guard error == nil, let image = image as? UIImage else {
                    self.controller?.error(error.debugDescription)
                    return
                }
                let fileName = "\(provider.suggestedName ?? UUID().uuidString).jpeg"
                // 80% JPEG quality gives a greater file size reduction with almost no loss in quality.
                // https://sirv.com/help/articles/jpeg-quality-comparison/
                guard let imageDataToSave = image.jpegData(compressionQuality: 0.8), imageDataToSave.count > 0 else {
                    self.controller?.error(LocalString._cant_open_the_file)
                    return
                }
                let fileData = ConcreteFileData(name: fileName, 
                                                mimeType: fileName.mimeType(),
                                                contents: imageDataToSave)
                self.controller?.fileSuccessfullyImported(as: fileData).cauterize()
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.rawImage.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.rawImage.identifier) { url, error in
                guard error == nil, let url = url else {
                    self.controller?.error(error.debugDescription)
                    return
                }
                addAttachment(from: url)
            }
        } else {
            self.controller?.error(LocalString._cant_open_the_file)
        }
    }

    private func addAttachment(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let fileData = ConcreteFileData(
                name: fileName,
                mimeType: fileName.mimeType(),
                contents: data
            )
            self.controller?.fileSuccessfullyImported(as: fileData).cauterize()
        } catch {
            self.controller?.error(error.localizedDescription)
        }
    }
}
