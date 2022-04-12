// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_Services

protocol ViewModeUpdater {
    func update(viewMode: ViewMode, completion: ((Swift.Result<ViewMode?, Error>) -> Void)?)
}

class UpdateViewModeService: ViewModeUpdater {

    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func update(viewMode: ViewMode, completion: ((Swift.Result<ViewMode?, Error>) -> Void)?) {
        let request = UpdateViewModeRequest(viewMode: viewMode)
        apiService.exec(route: request) { (dataTask, response: UpdateViewModeResponse) in
            if let error = dataTask?.error {
                completion?(.failure(error))
            } else {
                completion?(.success(response.viewMode))
            }
        }
    }
}
