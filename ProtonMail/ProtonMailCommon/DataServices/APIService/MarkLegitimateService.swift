//
//  MarkLegitimateService.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import PromiseKit
import ProtonCore_Services

class MarkLegitimateService {

    private let labelId: String
    private let apiService: APIService
    private let messageDataService: MessageDataService

    init(labelId: String, apiService: APIService, messageDataService: MessageDataService) {
        self.labelId = labelId
        self.apiService = apiService
        self.messageDataService = messageDataService
    }

    func markAsLegitimate(messageId: String) {
        _ = apiService.exec(route: MarkLegitimate(messageId: messageId))
            .done { [weak self, labelId] _ in
                self?.messageDataService.fetchEvents(labelID: labelId)
            }
    }

}
