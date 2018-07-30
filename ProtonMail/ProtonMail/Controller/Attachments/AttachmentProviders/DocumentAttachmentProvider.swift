//
//  DocumentAttachmentProvider.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 28/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class DocumentAttachmentProvider: NSObject, AttachmentProvider {
    internal weak var controller: AttachmentController!
    
    init(for controller: AttachmentController) {
        self.controller = controller
    }
    
    var alertAction: UIAlertAction {
        return UIAlertAction(title: LocalString._import_file_from_, style: UIAlertActionStyle.default, handler: { (action) -> Void in
            let types = [
                kUTTypeMovie as String,
                kUTTypeImage as String,
                kUTTypeText as String,
                kUTTypePDF as String,
                kUTTypeGNUZipArchive as String,
                kUTTypeBzip2Archive as String,
                kUTTypeZipArchive as String,
                kUTTypeData as String
            ]
            
            if #available(iOS 11.0, *) {
                // UIDocumentMenuViewController  will be deprecated in iOS 12 and since iOS 11 contains only one `Browse...` option which opens UIDocumentPickerViewController. We can avoid useless middle step.
                let picker = PMDocumentPickerViewController(documentTypes: types, in: .import)
                picker.delegate = self
                picker.allowsMultipleSelection = true
                self.controller.present(picker, animated: true, completion: nil)
            } else {
                // iOS 9 and 10 also allow access to document providers from UIDocumentPickerViewController, but let's keep Menu as it's still useful (until iOS 11)
                let importMenu = UIDocumentMenuViewController(documentTypes: types, in: .import)
                importMenu.delegate = self
                self.controller.present(importMenu, animated: true, completion: nil)
            }
        })
    }
    
    
    internal func process(fileAt url: URL) {
        let coordinator : NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
        var error : NSError?
        
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { [weak self] new_url in
            guard let `self` = self else { return }
            var fileData: FileData!
            
            #if APP_EXTENSION
                do {
                    let newUrl = try self.copyItemToTempDirectory(from: url)
                    let ext = url.mimeType()
                    let fileName = url.lastPathComponent
                    fileData = ConcreteFileData<URL>(name: fileName, ext: ext, contents: newUrl)
                } catch let error {
                    PMLog.D("Error while importing attachment: \(error.localizedDescription)")
                    self.controller.error(LocalString._cant_copy_the_file)
                }
                
            #else
                guard let data = try? Data(contentsOf: url) else {
                    self.controller.error(LocalString._cant_load_the_file)
                    return
                }
                fileData = ConcreteFileData<Data>(name: url.lastPathComponent, ext: url.mimeType(), contents: data)
            #endif
            
            self.controller.finish(fileData)
        }
        
        if error != nil {
            self.controller.error(LocalString._cant_copy_the_file)
        }
    }

    private func copyItemToTempDirectory(from oldUrl: URL) throws -> URL {
        let tempFileUrl = try FileManager.default.createTempURL(forCopyOfFileNamed: oldUrl.lastPathComponent)
        try FileManager.default.copyItem(at: oldUrl, to: tempFileUrl)
        return tempFileUrl
    }
}


@available(iOS, deprecated: 11.0, message: "We don't use UIDocumentMenuViewController for iOS 11+, only UIDocumentPickerViewController")
extension DocumentAttachmentProvider: UIDocumentMenuDelegate {
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.controller.present(documentPicker, animated: true, completion: nil)
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
            self.process(fileAt: url)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        PMLog.D("")
    }
}
