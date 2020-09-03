//
//  MessageAttachmentsCoordinator.swift
//  ProtonMail - Created on 18/03/2019.
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
        DispatchQueue.main.async {
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
            
            guard self.tempClearFileURL != nil else {
                return
            }
            
            let previewQL = QuickViewViewController()
            previewQL.dataSource = self
            previewQL.delegate = self
            self.controller?.present(previewQL, animated: true, completion: nil)
        }
    }
}

// delegate, datasource
extension MessageAttachmentsCoordinator: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    internal func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.tempClearFileURL != nil ? 1 : 0
    }
    
    internal func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.tempClearFileURL! as QLPreviewItem
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        guard let url = self.tempClearFileURL else {
            return
        }
        try? FileManager.default.removeItem(at: url)
        self.tempClearFileURL = nil
    }
}

extension MessageAttachmentsCoordinator: CoordinatorNew {
    func start() {
        // ?
    }
}
