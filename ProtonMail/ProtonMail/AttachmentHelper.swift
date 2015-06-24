//
//  AttachmentHelper.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation




public class AttachmentHelper {
    
    static func attachmentMake () {
        
    }
}

//if let attachments = attachments {
//    for (index, attachment) in enumerate(attachments) {
//        if let image = attachment as? UIImage {
//            if let fileData = UIImagePNGRepresentation(image) {
//                let attachment = Attachment(context: context)
//                attachment.attachmentID = "0"
//                attachment.message = message
//                attachment.fileName = "\(index).png"
//                attachment.mimeType = "image/png"
//                attachment.fileData = fileData
//                attachment.fileSize = fileData.length
//                continue
//            }
//        }
//        
//        let description = attachment.description ?? "unknown"
//        NSLog("\(__FUNCTION__) unsupported attachment type \(description)")
//    }
//}
