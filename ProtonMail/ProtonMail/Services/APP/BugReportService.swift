//
//  BugDataService.swift
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

import ProtonCoreAPIClient
import ProtonCoreServices

typealias BugReport = ReportBug

final class BugReportService {
    private let apiService: APIService

    init(api: APIService) {
        self.apiService = api
    }

    func reportPhishing(messageID: MessageID, messageBody: String, completion: ((NSError?) -> Void)?) {
        // If the body is armored, do not call the api.
        guard messageBody.unArmor == nil else {
            completion?(nil)
            return
        }
        let route = ReportPhishing(msgID: messageID.rawValue, mimeType: "text/html", body: messageBody)
        self.apiService.perform(request: route, response: VoidResponse()) { _, res in
            completion?(res.error?.toNSError)
        }
    }

    func reportBug(bugReport: BugReport) async throws {
        let request = ReportsBugs(bugReport)

        let files: [String: URL] = bugReport.files.reduce(into: [:]) { $0[$1.lastPathComponent] = $1 }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            apiService.performUpload(
                request: request,
                files: files,
                callCompletionBlockUsing: .immediateExecutor,
                uploadProgress: nil
            ) { task, result in
                if let error = task?.error ?? result.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
