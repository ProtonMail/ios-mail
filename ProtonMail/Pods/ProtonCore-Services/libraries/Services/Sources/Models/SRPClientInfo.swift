//
//  SRPClientInfo.swift
//  ProtonCore-Services - Created on 08.05.23.
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

public struct SRPClientInfo {
    public init(clientEphemeral: Data,
                clientProof: Data,
                expectedServerProof: Data) {
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.expectedServerProof = expectedServerProof
    }
    
    public let clientEphemeral: Data
    public let clientProof: Data
    public let expectedServerProof: Data
}
