//
//  MarkLegitimateService.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

import PromiseKit
import ProtonCore_Services

// sourcery: mock
protocol MarkLegitimateActionHandler: AnyObject {
    func markAsLegitimate(messageId: MessageID)
}

final class MarkLegitimateService: MarkLegitimateActionHandler {

    private let labelId: LabelID
    private let apiService: APIService
    private let eventsService: EventsFetching

    init(labelId: LabelID, apiService: APIService, eventsService: EventsFetching) {
        self.labelId = labelId
        self.apiService = apiService
        self.eventsService = eventsService
    }

    func markAsLegitimate(messageId: MessageID) {
        let request = MarkLegitimate(messageId: messageId),
        _ = apiService.perform(request: request, response: VoidResponse()) { [weak self, labelId] _, _ in
            self?.eventsService.fetchEvents(labelID: labelId)
        }
    }

}
