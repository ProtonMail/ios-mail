// Copyright (c) 2021 Proton AG
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

final class ReceiptService {
    private let labelID: LabelID
    private let apiService: APIService
    private let eventsService: EventsFetching

    init(labelID: LabelID, apiService: APIService, eventsService: EventsFetching) {
        self.labelID = labelID
        self.apiService = apiService
        self.eventsService = eventsService
    }

    func sendReceipt(messageID: MessageID) {
        let request = ReceiptRequest(messageID: messageID)
        apiService.exec(route: request, responseObject: VoidResponse()) { [weak self] _, _ in
            guard let id = self?.labelID else { return }
            self?.eventsService.fetchEvents(labelID: id)
        }
    }
}
