//
//  HumanCheckViewModel.swift
//  ProtonMail - Created on 12/28/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

class HumanCheckViewModel {
    typealias HumanResBlock = (_ token: String?, _ error: NSError?) -> Void
    typealias HumanCheckBlock = (_ error: NSError?) -> Void

    init() { }

    func getToken(_ complete: @escaping HumanResBlock) {
        fatalError("This method must be overridden")
    }

    func humanCheck(_ type: String, token: String, complete:@escaping HumanCheckBlock) {
        fatalError("This method must be overridden")
    }

}
