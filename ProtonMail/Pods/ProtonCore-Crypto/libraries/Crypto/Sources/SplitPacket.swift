//
//  SplitPacket.swift
//  ProtonCore-Crypto - Created on 07/15/22.
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

// this is same as SplitMessage. this ussually used when you try to split a armorded message into key packet and data packet.
public class SplitPacket {
    public init(dataPacket: Data, keyPacket: Data) {
        self.dataPacket = dataPacket
        self.keyPacket = keyPacket
    }
    
    public let dataPacket: Data
    public let keyPacket: Data
    
    var based64DataPacket: Based64String {
        return Based64String.init(raw: dataPacket)
    }
    
    var based64KeyPacket: Based64String {
        return Based64String.init(raw: keyPacket)
    }
}
