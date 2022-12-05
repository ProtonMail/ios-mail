//
//  ToolbarAction.swift
//  ProtonCore-DataModel - Created on 09/05/2022.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

public final class ToolbarActions: NSObject, NSCoding {
    /// Are the actions the same as the default toolbar actions.
    public var isCustom: Bool
    /// The list of actions of the toolbar
    public var actions: [String]

    init(isCustom: Bool, actions: [String]) {
        self.isCustom = isCustom
        self.actions = actions
    }

    init(rawValue: [String: Any]?) {
        self.isCustom = (rawValue?["IsCustom"] as? Bool) ?? false
        self.actions = (rawValue?["Actions"] as? [String]) ?? []
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ToolbarActions else {
            return false
        }
        return object.isCustom == self.isCustom &&
            object.actions == self.actions
    }

    public init?(coder: NSCoder) {
        isCustom = coder.decodeBool(forKey: "isCustom")
        actions = (coder.decodeObject(forKey: "actions") as? [String]) ?? []
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(isCustom, forKey: "isCustom")
        coder.encode(actions, forKey: "actions")
    }
}
