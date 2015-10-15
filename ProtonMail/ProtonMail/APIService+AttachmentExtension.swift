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
    func attachmentForAttachmentID(attachmentID: String, destinationDirectoryURL: NSURL, downloadTask: ((NSURLSessionDownloadTask) -> Void)?, completion: ((NSURLResponse?, NSURL?, NSError?) -> Void)?) {
        
        let filepath = destinationDirectoryURL.URLByAppendingPathComponent("\(attachmentID)")
        
        download(path: pathForAttachmentID(attachmentID), destinationDirectoryURL: filepath, downloadTask: downloadTask, completion: completion)
    }
    
    func attachmentDeleteForAttachmentID(attachmentID: String, completion: CompletionBlock?) {
        setApiVesion(1, appVersion: 1)
        request(method: .DELETE, path: pathForAttachmentID(attachmentID), parameters: nil, completion: completion)
    }
    
    // MARK: - Private methods
    
    private func pathForAttachmentID(attachmentID: String) -> String {
        return "/attachments/\(attachmentID)"
    }
    
}
