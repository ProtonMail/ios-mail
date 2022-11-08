//
//  FeatureFlag.swift
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

public struct FeatureFlag: OptionSet, Codable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// default. feature will simplely return isEnable.
    public static let `default`: FeatureFlag = []
    
    /// only avaliable for internal. if this is on. isenable will awasy false for none internal builds
    /// will check if DEBUG_CORE_INTERNALS defined . this will overried DEBUG_INTERNALS
    public static let availableCoreInternal = FeatureFlag(rawValue: 1 << 0) //1
    /// will check if DEBUG_INTERNALS defined. client side can add this to different core internal.
    public static let availableInternal = FeatureFlag(rawValue: 1 << 1) //2
    
    /// overried by local config. this works only when availableInternal  off
    public static let localOverride = FeatureFlag(rawValue: 1 << 2) //4
    /// overried by remote config. this works only when availableInternal off
    public static let remoteOverride = FeatureFlag(rawValue: 1 << 3) //8
}
