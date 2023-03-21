// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_Networking
import ProtonCore_Services

final class DownloadPageOperation: AsyncOperation {

    private let apiService: APIService
    private let endTime: Int
    private let labelID: LabelID
    private let pageSize: Int
    private let userID: UserID
    private(set) var result: Result<[ESMessage], Error>?

    init(
        apiService: APIService,
        endTime: Int,
        labelID: LabelID,
        pageSize: Int,
        userID: UserID
    ) {
        self.apiService = apiService
        self.endTime = endTime
        self.labelID = labelID
        self.pageSize = pageSize
        self.userID = userID
    }

    override func main() {
        super.main()

        let request = FetchMessagesByLabelRequest(
            labelID: labelID.rawValue,
            endTime: endTime,
            isUnread: false,
            pageSize: pageSize,
            priority: .lowestPriority
        )
        if isCancelled { return }

        apiService.perform(request: request) { [weak self] _, result in
            guard let self = self, !self.isCancelled else { return }
            switch result {
            case .failure(let error):
                self.log(message: "Download page operation failed \(error)", isError: true)
                self.result = .failure(error)
            case .success(let dict):
                self.result = self.parseDownloadMessagePage(response: dict)
            }
            self.finish()
        }
    }

    private func parseDownloadMessagePage(response dict: JSONDictionary) -> Result<[ESMessage], Error> {
        guard var messagesArray = dict["Messages"] as? [[String: Any]] else {
            log(message: "Parse message list (endTime \(endTime)) response failed, due to no Messages in dictionary")
            return .failure(NSError.unableToParseResponse(dict))
        }
        for index in messagesArray.indices {
            messagesArray[index]["UserID"] = userID.rawValue
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messagesArray)
            let messages = try JSONDecoder().decode([ESMessage].self, from: jsonData)
            if messages.isEmpty { return .success([]) }
            for index in messages.indices {
                messages[index].isDetailsDownloaded = false
            }
            let esMessages = messages.sorted(by: { $0.time > $1.time })
            log(message: "Parse message list (endTime \(endTime)) success, messages count \(esMessages.count)")
            return .success(esMessages)
        } catch {
            log(message: "Parse message list (endTime \(endTime)) response json failed \(error)")
            return .failure(error)
        }
    }
}
