//
//  ComposeContainerViewModel.swift
//  ProtonMail - Created on 15/04/2019.
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

extension ComposeContainerViewModel: Codable {
    enum CodingKeys: CodingKey {
        case messageID, messageAction
    }
    
    enum Errors: Error {
        case noUnderlyingMessage
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let message = self.childViewModel.message {
            try container.encode(message.messageID, forKey: .messageID)
        }
        try container.encode(self.childViewModel.messageAction.rawValue, forKey: .messageAction)
    }
}

class ComposeContainerViewModel: TableContainerViewModel {
    internal var childViewModel: ContainableComposeViewModel
    
    // for FileImporter
    internal lazy var documentAttachmentProvider = DocumentAttachmentProvider(for: self)
    internal lazy var imageAttachmentProvider = PhotoAttachmentProvider(for: self)
    internal let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000 // 25 mb
    
    init(editorViewModel: ContainableComposeViewModel) {
        self.childViewModel = editorViewModel
        super.init()
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let messageID = try container.decode(String.self, forKey: .messageID)
        let messageActionRaw = try container.decode(Int.self, forKey: .messageAction)
        
        guard let message = sharedMessageDataService.fetchMessages(withIDs: NSMutableSet(array: [messageID])).first,
            let action =  ComposeMessageAction(rawValue: messageActionRaw) else
        {
            throw Errors.noUnderlyingMessage
        }
        let childViewModel = ContainableComposeViewModel(msg: message, action: action)
        
        self.init(editorViewModel: childViewModel)
    }
    
    override var numberOfSections: Int {
        return 1
    }
    override func numberOfRows(in section: Int) -> Int {
        return 2
    }
    
    internal func filesExceedSizeLimit() -> Bool {
        return self.childViewModel.currentAttachmentsSize >= self.kDefaultAttachmentFileSize
    }
    
    internal func filesAreSupported(from itemProviders: [NSItemProvider]) -> Bool {
        return itemProviders.reduce(true) { $0 && $1.hasItem(types: self.filetypes) != nil }
    }
    
    internal func importFiles(from itemProviders: [NSItemProvider],
                              errorHandler: @escaping (String)->Void,
                              successHandler: @escaping ()->Void) {
        for itemProvider in itemProviders {
            guard let type = itemProvider.hasItem(types: self.filetypes) else { return }
            self.importFile(itemProvider, type: type, errorHandler: errorHandler, handler: successHandler)
        }
    }
}

extension ComposeContainerViewModel: FileImporter, AttachmentController {
    func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        fatalError()
    }
    var barItem: UIBarButtonItem? {
        return nil
    }
    func error(_ description: String) {
        self.showErrorBanner(description)
    }
    
    func fileSuccessfullyImported(as fileData: FileData) {
        guard self.childViewModel.currentAttachmentsSize + fileData.contents.dataSize < self.kDefaultAttachmentFileSize else {
            self.showErrorBanner(LocalString._the_total_attachment_size_cant_be_bigger_than_25mb)
            return
        }
        let attachment = fileData.contents.toAttachment(self.childViewModel.message!, fileName: fileData.name, type: fileData.ext)
        self.childViewModel.uploadAtt(attachment)
    }
}
