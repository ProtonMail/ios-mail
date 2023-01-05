//
//  ExternalAccountFeatureFlag.swift
//  ProtonCore-LoginUI-V5 - Created on 29.11.22.
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
//  along with ProtonCore. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_FeatureSwitch

extension Feature {
    public static var externalSignup = Feature.init(name: "externalSignup", isEnable: false)
    
    // control cap C features
    public static var externalAccountConversion = Feature.init(name: "externalAccountConversion", isEnable: false)
}
