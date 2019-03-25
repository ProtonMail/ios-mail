//
//  MessageAttachmentsCoordinator.swift
//  ProtonMail - Created on 18/03/2019.
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
import QuickLook
import PassKit

class MessageAttachmentsCoordinator: NSObject {
    private var tempClearFileURL: URL?
    private weak var controller: MessageAttachmentsViewController?
    
    init(controller: MessageAttachmentsViewController) {
        self.controller = controller
    }
    
    internal func error(_ error: NSError) {
        let alert = error.localizedDescription.alertController()
        alert.addOKAction()
        self.controller?.present(alert, animated: true, completion: nil)
    }
    
    internal func quickLook(clearfileURL: URL, fileName:String, type: String) {
        self.tempClearFileURL = clearfileURL // will use it in DataSource
        
        // FIXME: use UTI here instead of strings
        if (type == "application/vnd.apple.pkpass" || fileName.contains(check: ".pkpass") == true),
            let pkfile = try? Data(contentsOf: clearfileURL),
            let pass = try? PKPass(data: pkfile),
            let vc = PKAddPassesViewController(pass: pass),
            // as of iOS 12.0 SDK, PKAddPassesViewController will not be initialized on iPads without any warning 🤯
            (vc as UIViewController?) != nil
        {
            self.controller?.present(vc, animated: true, completion: nil)
            return
        }
        
        let previewQL = QuickViewViewController()
        previewQL.dataSource = self
        self.controller?.present(previewQL, animated: true, completion: nil)
    }
}

// delegate, datasource
extension MessageAttachmentsCoordinator: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    internal func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    internal func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.tempClearFileURL! as QLPreviewItem
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        /* Should we remove the clearfile here? */
        try? FileManager.default.removeItem(at: self.tempClearFileURL!)
        self.tempClearFileURL = nil
    }
}

extension MessageAttachmentsCoordinator: CoordinatorNew {
    func start() {
        // ?
    }
}
