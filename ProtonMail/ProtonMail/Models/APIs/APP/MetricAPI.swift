// Copyright (c) 2022 Proton AG
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
import ProtonCoreNetworking

struct MetricAPI {
    static let path: String = "/metrics"
}

final class MetricDarkMode: Request {
    private enum ParameterKeys: String {
        case log = "Log"
        case title = "Title"
        case data = "Data"
    }

    private enum LogType: String {
        case darkStyles = "dark_styles"
    }

    private enum Action: String {
        case applyDarkStyles = "apply_dark_styles"
        case removeDarkStyles = "remove_dark_styles"
    }

    private enum Title: String {
        case updateDarkStyles = "update_dark_styles"
    }

    var path: String { MetricAPI.path }

    var method: HTTPMethod { .post }
    let applyDarkStyle: Bool

    init(applyDarkStyle: Bool) {
        self.applyDarkStyle = applyDarkStyle
    }

    var parameters: [String: Any]? {
        if self.applyDarkStyle {
            let data = ["action": Action.applyDarkStyles.rawValue]
            let out: [String: Any] = [
                ParameterKeys.log.rawValue: LogType.darkStyles.rawValue,
                ParameterKeys.title.rawValue: Title.updateDarkStyles.rawValue,
                ParameterKeys.data.rawValue: data
            ]
            return out
        } else {
            let data = ["action": Action.removeDarkStyles.rawValue]
            let out: [String: Any] = [
                ParameterKeys.log.rawValue: LogType.darkStyles.rawValue,
                ParameterKeys.title.rawValue: Title.updateDarkStyles.rawValue,
                ParameterKeys.data.rawValue: data
            ]
            return out
        }
    }
}
