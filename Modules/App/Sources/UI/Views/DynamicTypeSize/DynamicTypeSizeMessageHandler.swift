// Copyright (c) 2025 Proton Technologies AG
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

import WebKit

final class DynamicTypeSizeMessageHandler: NSObject, WKScriptMessageHandlerWithReply {
    enum MessageName: String, CaseIterable {
        case scaleStyle
    }

    private let scalableProperties: [String] = ["font-size", "line-height"]

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) async -> (Any?, String?) {
        let styleString = message.body as! String
        let processedStyleString = applyScaling(to: styleString)
        return (processedStyleString, nil)
    }

    func applyScaling(to styleString: String) -> String {
        var styleProperties = CSSStyleCoder.decode(styleString: styleString)

        for propertyName in scalableProperties {
            guard
                let unscaledValueString = styleProperties[propertyName],
                let match = unscaledValueString.firstMatch(of: /([[:digit:]\.]+)(?:pt|px)/),
                let unscaledNumericalValue = Double(match.output.1),
                unscaledNumericalValue != 0
            else {
                continue
            }

            let scaledNumericalValue = UIFontMetrics.default.scaledValue(for: unscaledNumericalValue)
            let scaleFactor = scaledNumericalValue / unscaledNumericalValue
            let scaleFactorPropertyName = "--dts-\(propertyName)-scale-factor"

            styleProperties[scaleFactorPropertyName] = "\(scaleFactor)"
            styleProperties[propertyName] = "calc(\(match.output.0) * var(\(scaleFactorPropertyName))) !important"
        }

        styleProperties["overflow-wrap"] = "anywhere !important"
        styleProperties["text-wrap-mode"] = "wrap !important"

        return CSSStyleCoder.encode(properties: styleProperties)
    }
}

private enum CSSStyleCoder {
    static func decode(styleString: String) -> [String: String] {
        styleString.components(separatedBy: ";").reduce(into: [:]) { acc, keyValueString in
            let keyValuePair = keyValueString.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }

            if !keyValuePair.isEmpty {
                acc[keyValuePair[0]] = keyValuePair.last
            }
        }
    }

    static func encode(properties: [String: String]) -> String {
        properties.map { "\($0): \($1)" }.sorted().joined(separator: ";")
    }
}
