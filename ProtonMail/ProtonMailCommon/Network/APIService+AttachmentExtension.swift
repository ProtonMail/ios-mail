//
//  APIService+AttachmentExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

extension APIService {
    
    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    func downloadAttachment(byID attachmentID: String,
                            destinationDirectoryURL: URL,
                            customAuthCredential: AuthCredential? = nil,
                            downloadTask: ((URLSessionDownloadTask) -> Void)?,
                            completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        
        let filepath = destinationDirectoryURL.appendingPathComponent(attachmentID)
        download(byUrl: AppConstants.API_HOST_URL + pathForAttachmentID(attachmentID),
                 destinationDirectoryURL: filepath,
                 headers: ["x-pm-apiversion": 3],
                 customAuthCredential: customAuthCredential,
                 downloadTask: downloadTask,
                 completion: completion)
    }
    
    func attachmentDeleteForAttachmentID(_ attachmentID: String, completion: CompletionBlock?) {
        //setApiVesion(1, appVersion: 1)
        request(method: .delete, path: pathForAttachmentID(attachmentID), parameters: nil, headers: ["x-pm-apiversion": 3], completion: completion)
    }
    
    // MARK: - Private methods
    fileprivate func pathForAttachmentID(_ attachmentID: String) -> String {
        return AppConstants.API_PATH + "/attachments/\(attachmentID)"
    }
    
}
