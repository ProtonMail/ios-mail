//
//  InitialReturn.swift
//  ProtonCore-TestingToolkit - Created on 13/09/2021.
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

public enum Absent: Int, Equatable, Codable { case nothing }

public struct InitialReturn<Input, Output> {
    let closure: (Input) throws -> Output

    init(_ closure: @escaping (Input) throws -> Output) {
        self.closure = closure
    }

    public static var crash: InitialReturn<Input, Output> {
        .init { _ in
            fatalError("Stub setup error — you must provide a default value of type \(Output.self) if this stub is ever called!")
        }
    }
}
