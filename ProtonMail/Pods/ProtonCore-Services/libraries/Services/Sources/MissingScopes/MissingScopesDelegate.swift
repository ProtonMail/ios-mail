//
//  MissingScopesDelegate.swift
//  ProtonCore-Services - Created on 26.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreNetworking

public protocol MissingScopesDelegate: AnyObject {
    func onMissingScopesHandling(username: String, responseHandlerData: PMResponseHandlerData, completion: @escaping (MissingScopesFinishReason) -> Void)
    func showAlert(title: String, message: String?)
}

public enum MissingScopesFinishReason {
    case unlocked
    case closed
    case closedWithError(code: Int, description: String)
}
