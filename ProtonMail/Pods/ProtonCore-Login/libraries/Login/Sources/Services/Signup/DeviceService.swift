//
//  DeviceService.swift
//  ProtonCore-Login - Created on 11/03/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
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
import DeviceCheck

protocol DeviceServiceProtocol {
    func generateToken(result: @escaping (Result<String, SignupError>) -> Void)
}

class DeviceService: DeviceServiceProtocol {

    let device: DCDevice
    init(device: DCDevice = DCDevice.current) {
        self.device = device
    }

    func generateToken(result: @escaping (Result<String, SignupError>) -> Void) {
        guard device.isSupported else {
            DispatchQueue.main.async {
                result(.failure(SignupError.deviceTokenUnsuported))
            }
            return
        }
        device.generateToken(completionHandler: { (data, error) in
            DispatchQueue.main.async {
                if let tokenData = data {
                    result(.success(tokenData.base64EncodedString()))
                } else if let error = error {
                    #if targetEnvironment(simulator)
                        result(.success("test"))
                    #else
                        result(.failure(SignupError.generic(message: error.localizedDescription)))
                    #endif
                } else {
                    result(.failure(SignupError.deviceTokenError))
                }
            }
        })
    }
}
