//
//  Feature.swift
//  ProtonCore-FeatureSwitch - Created on 9/20/22.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.
//

/// the feature
/// TODO:: add encode & decode for parsing local/remote file
public struct Feature {
    
    public init(name: String, isEnable: Bool = false) {
        self.init(name: name, isEnable: isEnable, flags: [])
    }
    
    // foroge this for now. it is for supporting exsiting feature flag
    public init(name: String, isEnable: Bool, flags: FeatureFlag) {
        self.name = name
        self.isEnable = isEnable
        self.featureFlags = flags
    }
    
    /// feature name.
    let name: String
    
    // use it later
    let version: Version? = nil
    
    // default status
    var isEnable: Bool
    
    // more visiblity/modification control
    var featureFlags: FeatureFlag
    
    public func `copy`(isEnable: Bool) -> Feature {
        return Feature.init(name: self.name, isEnable: isEnable, flags: self.featureFlags)
    }
    
    public static func Parse(dict: [String: Any]) -> Feature? {
        guard let name = dict["name"] as? String else {
            return nil
        }
        guard let isEnable = dict["isEnable"] as? Bool else {
            return nil
        }
        return .init(name: name, isEnable: isEnable, flags: [])
    }
}
