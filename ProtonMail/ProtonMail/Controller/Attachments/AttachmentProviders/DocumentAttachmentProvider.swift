//
//  DocumentAttachmentProvider.swift
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

import CoreServices
import Foundation
import PromiseKit
import ProtonCore_UIFoundations

protocol FileCoordinationProvider {
    func coordinate(readingItemAt url: URL, options: NSFileCoordinator.ReadingOptions, error: NSErrorPointer, byAccessor: (URL) -> Void)
}

extension NSFileCoordinator: FileCoordinationProvider { }

class DocumentAttachmentProvider: NSObject, AttachmentProvider {
    internal weak var controller: AttachmentController?
    private let coordinator: FileCoordinationProvider

    init(for controller: AttachmentController, coordinator: FileCoordinationProvider = NSFileCoordinator(filePresenter: nil)) {
        self.controller = controller
        self.coordinator = coordinator
    }

    var actionSheetItem: PMActionSheetItem {
        PMActionSheetPlainItem(title: LocalString._import_from,
                               icon: IconProvider.fileArrowIn,
                               iconColor: ColorProvider.IconNorm) { (_) -> Void in
            let types = [
                kUTTypeMovie as String,
                kUTTypeVideo as String,
                kUTTypeImage as String,
                kUTTypeText as String,
                kUTTypePDF as String,
                kUTTypeGNUZipArchive as String,
                kUTTypeBzip2Archive as String,
                kUTTypeZipArchive as String,
                kUTTypeData as String,
                kUTTypeVCard as String
            ]

            let picker = PMDocumentPickerViewController(documentTypes: types, in: .import)
            picker.delegate = self
            picker.allowsMultipleSelection = true
            self.controller?.present(picker, animated: true, completion: nil)
        }
    }

    internal func process(fileAt url: URL, completion: @escaping () -> Void) {
        var coordinatorError : NSError?

        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatorError) { [weak self] new_url in
            guard let self = self else {
                completion()
                return
            }

            let fileData: FileData

            do {
#if APP_EXTENSION
                let newUrl = try self.copyItemToTempDirectory(from: url)
                let ext = url.mimeType()
                let fileName = url.lastPathComponent
                fileData = ConcreteFileData<URL>(name: fileName, ext: ext, contents: newUrl)
#else
                _ = url.startAccessingSecurityScopedResource()
                let data = try Data(contentsOf: url)
                url.stopAccessingSecurityScopedResource()
                fileData = ConcreteFileData<Data>(name: url.lastPathComponent, ext: url.mimeType(), contents: data)
#endif
            } catch {
                presentError(error)
                completion()
                return
            }

            guard let controller = self.controller else {
                // End process
                return completion()
            }

            controller.fileSuccessfullyImported(as: fileData).done {
                completion()
            }.catch { error in
                self.presentError(error)
                completion()
            }
        }

        if let err = coordinatorError {
            presentError(err)
            completion()
        }
    }

    private func presentError(_ error: Error) {
#if APP_EXTENSION
        self.controller?.error(LocalString._cant_copy_the_file)
#else
        self.controller?.error(LocalString._cant_load_the_file)
#endif
    }

    private func copyItemToTempDirectory(from oldUrl: URL) throws -> URL {
        let tempFileUrl = try FileManager.default.createTempURL(forCopyOfFileNamed: oldUrl.lastPathComponent)
        try FileManager.default.copyItem(at: oldUrl, to: tempFileUrl)
        return tempFileUrl
    }
}

/// Documents
extension DocumentAttachmentProvider: UIDocumentPickerDelegate {
    @available(iOS 11.0, *)
    internal func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        urls.forEach { self.documentPicker(controller, didPickDocumentAt: $0) }
    }
    
    internal func documentPicker(_ documentController: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        // TODO: at least on iOS 11.3.1, DocumentPicker does not call this method until whole file will be downloaded from the cloud. This should be a bug, but in future we can check size of document before downloading it
        // FileManager.default.attributesOfItem(atPath: url.path)[NSFileSize]
        
        DispatchQueue.global().async {
            self.process(fileAt: url) { }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { }
}
