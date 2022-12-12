// Copyright (c) 2022 Proton Technologies AG
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

final class ContentBlockRuleBuilder {
    private var rules: [Rule] = []

    func add(rule: Rule) -> Self {
        rules.append(rule)
        return self
    }

    func export() -> String? {
        let rawValues = rules.map { $0.export() }
        if let data = try? JSONSerialization.data(withJSONObject: rawValues, options: .prettyPrinted),
           let result = String(data: data, encoding: .utf8) {
            return result
        }
        return nil
    }

}

extension ContentBlockRuleBuilder.Rule {
    enum Key: String {
        case trigger, action
    }

    enum TriggerField: String {
        case urlFilter = "url-filter"
    }

    enum ActionField: String {
        case type
    }

    enum Action: String {
        case block
        case ignorePreviousRules = "ignore-previous-rules"
    }
}

extension ContentBlockRuleBuilder {
    final class Rule {
        private var trigger: [String: String] = [:]
        private var action: [String: String] = [:]

        func addTrigger(key: TriggerField, value: String) -> Self {
            trigger[key.rawValue] = value
            return self
        }

        func addAction(key: ActionField, value: Action) -> Self {
            action[key.rawValue] = value.rawValue
            return self
        }

        func export() -> [String: [String: String]] {
            [
                Key.trigger.rawValue: trigger,
                Key.action.rawValue: action
            ]
        }
    }
}
