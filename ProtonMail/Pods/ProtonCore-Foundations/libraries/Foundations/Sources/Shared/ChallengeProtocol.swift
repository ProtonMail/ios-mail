//
//  ChallengeProtocol.swift
//  ProtonCore-TestingToolkit - Created on 09.06.2021.
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

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum ChallengeTextFieldType {
    /// TextField for username
    case username
    case username_email
    /// TextField for password
    case password
    /// TextField for password confirm
    case confirm
    /// TextField for recovery mail
    case recoveryMail
    /// TextField for recovery phone
    case recoveryPhone
    /// TextField for verification
    case verification
}

public protocol ChallengeProtocol {

  #if canImport(UIKit)
  func observeTextField(_ textField: UITextField, type: ChallengeTextFieldType, ignoreDelegate: Bool) throws
  #endif
}

extension ChallengeProtocol {
  #if canImport(UIKit)
  public func observeTextField(_ textField: UITextField, type: ChallengeTextFieldType) throws {
    try observeTextField(textField, type: type, ignoreDelegate: false)
  }
  #endif 
}
