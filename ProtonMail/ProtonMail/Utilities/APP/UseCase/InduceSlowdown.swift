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

import MBProgressHUD
import ProtonCoreNetworking
import ProtonCoreServices

/*
 The purpose of this is to test how the app handles the load when the event loop receives a lot of messages.
 It will apply a test label to all messages in an account, and then detach it, generating a great number of events.
 The events will be fetched and processed gradually, testing how well the database and the UI can take it.
 */
struct InduceSlowdown: Sendable {
    private let user: UserManager

    init(user: UserManager) {
        self.user = user
    }

    func execute() async throws {
#if DEBUG_ENTERPRISE
        let testLabelID = try await ensureTestLabelExistsAndObtainItsID()

        await showToast(message: "Fetching IDs of all messages...")

        let messageIDs = try await fetchAllMessageIDs()
        log(message: "Found \(messageIDs.count) ids")

        await showToast(message: "Applying the test label to \(messageIDs.count) messages...")

        try await applyTestLabel(labelID: testLabelID, to: messageIDs)
        try await detachTestLabel(labelID: testLabelID)

        await showToast(message: "Done, wait for the event loop to start processing events.")
#else
        fatalError("This should not be available in production")
#endif
    }

    private func fetchAllMessageIDs(accumulator: [String] = []) async throws -> [String] {
        let request = FetchMessageIDsRequest(afterID: accumulator.last, limit: 1_000)
        let response: FetchMessageIDsResponse = try await user.apiService.perform(request: request).1

        if response.IDs.isEmpty {
            return accumulator
        } else {
            return try await fetchAllMessageIDs(accumulator: accumulator + response.IDs)
        }
    }

    private func ensureTestLabelExistsAndObtainItsID() async throws -> LabelID {
        let testLabelName = "MAILIOS-3743: Artificial slowdown test"
        let testLabelColor = ColorManager.forLabel[1]

        let allLabels = user.labelService.getAllLabels(of: .label)

        if let existingTestLabel = allLabels.first(where: { $0.name == testLabelName }) {
            log(message: "Label \(testLabelName) already exists")
            return existingTestLabel.labelID
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                user.labelService.createNewLabel(name: testLabelName, color: testLabelColor) { rawLabelID, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let rawLabelID {
                        self.log(message: "Created label \(testLabelName)")
                        continuation.resume(returning: LabelID(rawLabelID))
                    } else {
                        fatalError("invalid state")
                    }
                }
            }
        }
    }

    private func applyTestLabel(labelID: LabelID, to messageIDs: [String]) async throws {
        let messageIDChunks = messageIDs.chunked(into: 150)

        try await withThrowingTaskGroup(of: OptionalErrorResponse.self) { group in
            for (chunkIndex, messageIDChunk) in messageIDChunks.enumerated() {
                let request = ApplyLabelToMessagesRequest(labelID: labelID, messages: messageIDChunk)

                group.addTask {
                    self.log(message: "Applying test label to chunk #\(chunkIndex) (\(messageIDChunk.count) messages)")
                    return try await self.user.apiService.perform(request: request).1
                }
            }

            for try await response in group {
                try response.validate()
            }
        }
    }

    private func detachTestLabel(labelID: LabelID) async throws {
        let request = DetachLabelRequest(labelID: labelID)
        log(message: "Detaching label \(labelID)")

        let response: OptionalErrorResponse = try await user.apiService.perform(request: request).1
        try response.validate()
    }

    private func log(message: String) {
        SystemLogger.log(message: message, category: .artificialSlowdown)
    }

    @MainActor
    private func showToast(message: String) {
        guard let window = UIApplication.shared.topMostWindow else {
            return
        }

        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = message
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }
}

struct FetchMessageIDsRequest: Request {
    let parameters: [String: Any]?

    init(afterID: String? = nil, limit: Int? = nil) {
        var params: [String: Any] = [:]
        params["AfterID"] = afterID
        params["Limit"] = limit
        parameters = params.isEmpty ? nil : params
    }

    var path: String {
        "\(MessageAPI.path)/ids"
    }
}

struct FetchMessageIDsResponse: Decodable {
    let IDs: [String]
}

struct DetachLabelRequest: Request {
    let path: String

    var method: HTTPMethod {
        .put
    }

    init(labelID: LabelID) {
        path = "\(LabelAPI.versionPrefix)\(LabelAPI.path)/\(labelID.rawValue)/detach"
    }
}

struct OptionalErrorResponse: APIDecodableResponse {
    let code: Int
    let error: String?

    func validate() throws {
        if let error {
            throw NSError.protonMailError(code, localizedDescription: error)
        } else if !(1_000...1_001).contains(code) {
            throw NSError.protonMailError(code, localizedDescription: "Invalid response code: \(code)")
        }
    }
}
