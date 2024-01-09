//
//  FileImporter.swift
//  Proton Mail - Created on 29/04/2019.
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

import CoreServices
import PromiseKit
import UniformTypeIdentifiers

enum FileImporterConstants {
    static var fileTypes: [String] {
        // list from Share extension NSExtensionActivationRule, except text and URLs. Full list here:
        // https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
        return ["public.file-url", "public.xml", "com.adobe.pdf", "public.image", "public.playlist", "public.archive", "public.spreadsheet", "public.presentation", "public.calendar-event", "public.vcard", "public.executable", "public.audiovisual-​content", "public.font", "com.microsoft.word.doc", "com.microsoft.excel.xls", "com.microsoft.powerpoint.​ppt", "public.audio", "public.movie"]
    }
}

protocol FileImporter {
    func importFile(_ itemProvider: NSItemProvider, type: String, errorHandler: @escaping (String) -> Void, handler: @escaping () -> Void)
    func fileSuccessfullyImported(as fileData: FileData) -> Promise<Void>

    var documentAttachmentProvider: DocumentAttachmentProvider { get }
    var imageAttachmentProvider: PhotoAttachmentProvider { get }
}

extension FileImporter {

    func importFile(_ itemProvider: NSItemProvider,
                    type: String,
                    errorHandler: @escaping (String) -> Void,
                    handler: @escaping () -> Void) {
        if type == UTType.image.identifier {
            handleImageItem(itemProvider, errorHandler: errorHandler, handler: handler)
        } else {
            itemProvider.loadItem(forTypeIdentifier: type, options: nil) { item, error in
                guard error == nil else {
                    errorHandler(error?.localizedDescription ?? "")
                    handler()
                    return
                }

                if let url = item as? URL {
                    documentAttachmentProvider.process(fileAt: url) {
                        handler()
                    }
                } else if let img = item as? UIImage {
                    self.imageAttachmentProvider.process(original: img).ensure {
                        handler()
                    }.cauterize()
                } else if (type as CFString == kUTTypeVCard), let data = item as? Data {
                    var fileName = "\(NSUUID().uuidString).vcf"
                    if let name = itemProvider.suggestedName {
                        fileName = name
                    }
                    let fileData = ConcreteFileData(name: fileName, mimeType: "text/vcard", contents: data)
                    self.fileSuccessfullyImported(as: fileData).ensure {
                        handler()
                    }.cauterize()
                } else if let data = item as? Data {
                    var fileName = NSUUID().uuidString
                    if let name = itemProvider.suggestedName {
                        fileName = name
                    }

                    let type = (itemProvider.registeredTypeIdentifiers.first ?? type) as CFString
                    // this method does not work correctly with "text/vcard" mime by some reson, so VCards have separate `else if`
                    guard let filetype = UTTypeCopyPreferredTagWithClass(type, kUTTagClassFilenameExtension)?.takeRetainedValue() as String?,
                          let mimetype = UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType)?.takeRetainedValue() as String? else {
                        errorHandler(LocalString._failed_to_determine_file_type)
                        handler()
                        return
                    }
                    let fileData = ConcreteFileData(name: fileName + "." + filetype, mimeType: mimetype, contents: data)
                    self.fileSuccessfullyImported(as: fileData).ensure {
                        handler()
                    }.cauterize()
                } else {
                    errorHandler(LocalString._unsupported_file)
                    handler()
                }
            }
        }
    }

    private func handleImageItem(
        _ itemProvider: NSItemProvider,
        errorHandler: @escaping (String) -> Void,
        handler: @escaping () -> Void
    ) {
        itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
            guard let data = data else {
                errorHandler(error?.localizedDescription ?? "")
                handler()
                return
            }
            guard let image = UIImage(data: data) else {
                // Loaded data is not UIImage, try screenshot handler
                handleScreenshotItem(itemProvider, errorHandler: errorHandler, handler: handler)
                return
            }
            self.imageAttachmentProvider.process(original: image).ensure {
                handler()
            }.catch { error in
                errorHandler(error.localizedDescription)
                handler()
            }
        }
    }

    private func handleScreenshotItem(
        _ itemProvider: NSItemProvider,
        errorHandler: @escaping (String) -> Void,
        handler: @escaping () -> Void
    ) {
        let registeredTypeIdentifiers = itemProvider.registeredTypeIdentifiers
        guard let typeIdentifier = registeredTypeIdentifiers.first else {
            errorHandler(LocalString._unsupported_file)
            handler()
            return
        }
        itemProvider.loadItem(forTypeIdentifier: typeIdentifier) { item, error in
            guard let item = item, error == nil else {
                errorHandler(error?.localizedDescription ?? "")
                handler()
                return
            }
            var imageAbleToImport: UIImage?
            if let screenShotImage = item as? UIImage,
               let imageData = screenShotImage.jpegData(compressionQuality: 0.8), // Handle the screenshot here
               let jpegImage = UIImage(data: imageData) {
                imageAbleToImport = jpegImage
            } else if let url = item as? URL, let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                imageAbleToImport = image
            }
            guard let imageAbleToImport = imageAbleToImport else {
                errorHandler(LocalString._unsupported_file)
                handler()
                return
            }
            self.imageAttachmentProvider.process(original: imageAbleToImport).ensure {
                handler()
            }.catch { error in
                errorHandler(error.localizedDescription)
                handler()
                return
            }
        }
    }
}

extension NSItemProvider {
    func hasItem(types: [String]) -> String? {
        return types.first(where: self.hasItemConformingToTypeIdentifier)
    }
}
