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
import ProtonCore_Networking

struct MetricAPI {
    static let path: String = "/metrics"
}

final class MetricDarkMode: Request {
    private enum ParameterKeys: String {
        case log = "Log"
        case title = "Title"
        case Data = "Data"
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
                ParameterKeys.Data.rawValue: data
            ]
            return out
        } else {
            let data = ["action": Action.removeDarkStyles.rawValue]
            let out: [String: Any] = [
                ParameterKeys.log.rawValue: LogType.darkStyles.rawValue,
                ParameterKeys.title.rawValue: Title.updateDarkStyles.rawValue,
                ParameterKeys.Data.rawValue: data
            ]
            return out
        }
    }
}

// https://confluence.protontech.ch/display/CRYPTO/Logs+collection
final class MetricEncryptedSearch: Request {
    private enum ParameterKeys: String {
        case log = "Log"
        case title = "Title"
        case Data = "Data"
    }

    enum MetricType: String {
        case index, search
    }

    var path: String { MetricAPI.path }

    var method: HTTPMethod { .post }
    private let metricType: MetricType
    private let data: [String: Any]

    init(type: MetricType, data: [String: Any]) {
        self.metricType = type
        self.data = data
    }

    var parameters: [String: Any]? {
        [
            ParameterKeys.log.rawValue: "encrypted_search",
            ParameterKeys.title.rawValue: metricType.rawValue,
            ParameterKeys.Data.rawValue: data
        ]
    }
}
