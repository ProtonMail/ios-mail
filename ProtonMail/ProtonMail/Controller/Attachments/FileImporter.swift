//
//  FileImporter.swift
//  ProtonMail - Created on 29/04/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation

protocol FileImporter {
    func importFile(_ itemProvider: NSItemProvider, type: String, errorHandler: @escaping (String)->Void, handler: @escaping ()->Void)
    func fileSuccessfullyImported(as fileData: FileData)
    
    var documentAttachmentProvider: DocumentAttachmentProvider { get }
    var imageAttachmentProvider: PhotoAttachmentProvider { get }
}

extension FileImporter {
    var filetypes: [String] {
        // list from Share extension NSExtensionActivationRule, except text and URLs
        return ["public.file-url", "public.xml", "com.adobe.pdf", "public.image", "public.playlist", "public.archive", "public.spreadsheet", "public.presentation", "public.calendar-event", "public.vcard"]
    }
    
    func importFile(_ itemProvider: NSItemProvider,
                    type: String,
                    errorHandler: @escaping (String)->Void,
                    handler: @escaping ()->Void)
    {
        itemProvider.loadItem(forTypeIdentifier: type, options: nil) { item, error in // async
            defer {
                // important: whole this closure contents will be run synchronously, so we can call the handler in the end of scope
                // if this situation will change some day, handler should be passed over
                handler()
            }
            
            guard error == nil else {
                errorHandler(error?.localizedDescription ?? "")
                return
            }
            
            //TODO:: the process(XXX:) functions below. they could be abstracted out. all type of process in the same place.
            if let url = item as? URL {
                self.documentAttachmentProvider.process(fileAt: url) // sync
            } else if let img = item as? UIImage {
                self.imageAttachmentProvider.process(original: img) // sync
            } else if (type as CFString == kUTTypeVCard), let data = item as? Data {
                var fileName = "\(NSUUID().uuidString).vcf"
                if #available(iOS 11.0, *), let name = itemProvider.suggestedName {
                    fileName = name
                }
                let fileData = ConcreteFileData<Data>(name: fileName, ext: "text/vcard", contents: data)
                self.fileSuccessfullyImported(as: fileData)
            } else if let data = item as? Data {
                var fileName = NSUUID().uuidString
                if #available(iOS 11.0, *), let name = itemProvider.suggestedName {
                    fileName = name
                }
                
                let type = (itemProvider.registeredTypeIdentifiers.first ?? type) as CFString
                // this method does not work correctly with "text/vcard" mime by some reson, so VCards have separate `else if`
                guard let filetype = UTTypeCopyPreferredTagWithClass(type, kUTTagClassFilenameExtension)?.takeRetainedValue() as String?,
                    let mimetype = UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType)?.takeRetainedValue() as String? else
                {
                    errorHandler(LocalString._failed_to_determine_file_type)
                    return
                }
                let fileData = ConcreteFileData<Data>(name: fileName + "." + filetype, ext: mimetype, contents: data)
                self.fileSuccessfullyImported(as: fileData)
            } else {
                errorHandler(LocalString._unsupported_file)
            }
        }
    }
}

extension NSItemProvider {
    func hasItem(types: [String]) -> String? {
        return types.first(where: self.hasItemConformingToTypeIdentifier)
    }
}
