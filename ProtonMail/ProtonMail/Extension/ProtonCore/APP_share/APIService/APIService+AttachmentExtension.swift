//
//  APIService+AttachmentExtension.swift
//  Proton Mail
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

import Foundation
import ProtonCore_Networking
import ProtonCore_Services

extension APIService {

    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    func downloadAttachment(byID attachmentID: String,
                            destinationDirectoryURL: URL,
                            customAuthCredential: AuthCredential? = nil,
                            downloadTask: ((URLSessionDownloadTask) -> Void)?,
                            completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {

        let filepath = destinationDirectoryURL.appendingPathComponent(attachmentID)
        self.download(byUrl: self.doh.getCurrentlyUsedHostUrl() + pathForAttachmentID(attachmentID),
                      destinationDirectoryURL: filepath,
                      headers: .empty,
                      authenticated: true,
                      customAuthCredential: customAuthCredential,
                      downloadTask: downloadTask,
                      completion: completion)
    }

    // MARK: - Private methods
    fileprivate func pathForAttachmentID(_ attachmentID: String) -> String {
//        return self.serverConfig.path + "/attachments/\(attachmentID)"
        return "/attachments/\(attachmentID)"
    }

}
