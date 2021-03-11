//
//  FileImporter.swift
//  ProtonMail - Created on 29/04/2019.
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
import PromiseKit

protocol FileImporter {
    func importFile(_ itemProvider: NSItemProvider, type: String, errorHandler: @escaping (String)->Void, handler: @escaping ()->Void)
    func fileSuccessfullyImported(as fileData: FileData) -> Promise<Void>
    
    var documentAttachmentProvider: DocumentAttachmentProvider { get }
    var imageAttachmentProvider: PhotoAttachmentProvider { get }
}

extension FileImporter {
    var filetypes: [String] {
        // list from Share extension NSExtensionActivationRule, except text and URLs. Full list here:
        // https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
        return ["public.file-url", "public.xml", "com.adobe.pdf", "public.image", "public.playlist", "public.archive", "public.spreadsheet", "public.presentation", "public.calendar-event", "public.vcard", "public.executable", "public.audiovisual-​content", "public.font", "com.microsoft.word.doc", "com.microsoft.excel.xls", "com.microsoft.powerpoint.​ppt", "public.audio", "public.movie"]
    }
    
    func importFile(_ itemProvider: NSItemProvider,
                    type: String,
                    errorHandler: @escaping (String)->Void,
                    handler: @escaping ()->Void)
    {
        itemProvider.loadItem(forTypeIdentifier: type, options: nil) { item, error in // async            
            guard error == nil else {
                errorHandler(error?.localizedDescription ?? "")
                handler()
                return
            }
            
            //TODO:: the process(XXX:) functions below. they could be abstracted out. all type of process in the same place.
            if let url = item as? URL {
                self.documentAttachmentProvider.process(fileAt: url).ensure {
                    handler()
                }.cauterize()
            } else if let img = item as? UIImage {
                self.imageAttachmentProvider.process(original: img).ensure {
                    handler()
                }.cauterize()
            } else if (type as CFString == kUTTypeVCard), let data = item as? Data {
                var fileName = "\(NSUUID().uuidString).vcf"
                if let name = itemProvider.suggestedName {
                    fileName = name
                }
                let fileData = ConcreteFileData<Data>(name: fileName, ext: "text/vcard", contents: data)
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
                    let mimetype = UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType)?.takeRetainedValue() as String? else
                {
                    errorHandler(LocalString._failed_to_determine_file_type)
                    handler()
                    return
                }
                let fileData = ConcreteFileData<Data>(name: fileName + "." + filetype, ext: mimetype, contents: data)
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

extension NSItemProvider {
    func hasItem(types: [String]) -> String? {
        return types.first(where: self.hasItemConformingToTypeIdentifier)
    }
}
